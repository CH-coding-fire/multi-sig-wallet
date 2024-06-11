// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract MultiSigWallet {
    event ReceivedEth(uint256 indexed amount);
    event SendEthSuccessful(uint256 indexed amount);
    error MultiSigWallet__UnknownError();
    error MultiSigWallet__NoAddress();
    error MultiSigWallet__NotOwner();
    error MultiSigWallet__NoTxIndex();
    error MultiSigWallet__NotEnoughApproval();
    error MultiSigWallet__TxFail();
    error MultiSigWallet__AlreadyExecuted();
    error MultiSigWallet__OwnerNotInApprovalList();
    error MultiSigWallet__OwnerAlreadyApproved();
    address[] private s_owners;
    uint256 private s_minApproval;
    struct TxDetails {
        address s_targetAddress;
        uint256 s_ethSendAmount;
        address[] s_approvedOwners;
        bool isExist;
        bool isExecuted;
    }
    mapping(uint256 => TxDetails) private s_txRecords;
    uint256 private s_latestTxIndex;

    constructor(address[] memory ownerAddresses, uint minApproval) {
        if (ownerAddresses.length == 0) {
            revert MultiSigWallet__NoAddress();
        }
        s_owners = ownerAddresses;
        s_minApproval = minApproval;
        s_latestTxIndex = 0;
    }

    receive() external payable {
        emit ReceivedEth(msg.value);
        // emit RandomEvent(msg.value);
    }

    fallback() external {
        revert MultiSigWallet__UnknownError();
    }

    function requestTx(
        address targetAddress,
        uint256 ethSendAmount
    ) external isOwner returns (uint256) {
        s_latestTxIndex++;
        s_txRecords[s_latestTxIndex].s_targetAddress = targetAddress;
        s_txRecords[s_latestTxIndex].s_approvedOwners.push(msg.sender);
        s_txRecords[s_latestTxIndex].isExist = true;
        s_txRecords[s_latestTxIndex].s_ethSendAmount = ethSendAmount;
        return s_latestTxIndex;
    }

    function approveTx(
        uint256 txIndex
    ) external isOwner isTxIndexExists(txIndex) {
        for (
            uint256 i = 0;
            i < s_txRecords[txIndex].s_approvedOwners.length;
            i++
        ) {
            if (s_txRecords[txIndex].s_approvedOwners[i] == msg.sender) {
                revert MultiSigWallet__OwnerAlreadyApproved();
            }
        }

        s_txRecords[txIndex].s_approvedOwners.push(msg.sender);
    }

    function executeTx(
        uint256 txIndex
    ) external isOwner isTxIndexExists(txIndex) {
        if (s_txRecords[txIndex].isExecuted) {
            revert MultiSigWallet__AlreadyExecuted();
        }
        if (s_txRecords[txIndex].s_approvedOwners.length < s_minApproval) {
            revert MultiSigWallet__NotEnoughApproval();
        }
        (bool success, ) = s_txRecords[txIndex].s_targetAddress.call{
            value: s_txRecords[txIndex].s_ethSendAmount
        }("");
        if (!success) {
            revert MultiSigWallet__TxFail();
        }
        s_txRecords[txIndex].isExecuted = true;
    }

    function revokeApproval(
        uint256 txIndex
    ) external isOwner isTxIndexExists(txIndex) {
        if (
            !checkOwnerIsInApprovedOwner(
                s_txRecords[txIndex].s_approvedOwners,
                msg.sender
            )
        ) {
            revert MultiSigWallet__OwnerNotInApprovalList();
        }

        // Directly modify the storage array
        address[] storage approvedOwners = s_txRecords[txIndex]
            .s_approvedOwners;

        uint256 targetIndex = 0;
        for (uint256 i = 0; i < approvedOwners.length; i++) {
            if (approvedOwners[i] == msg.sender) {
                targetIndex = i;
                break;
            }
        }

        // Shift elements to the left to overwrite the item to be removed
        for (uint256 i = targetIndex; i < approvedOwners.length - 1; i++) {
            approvedOwners[i] = approvedOwners[i + 1];
        }

        // Remove the last element
        approvedOwners.pop();
    }

    function checkOwnerIsInApprovedOwner(
        address[] memory approvedOwners,
        address msgOwner
    ) private pure returns (bool) {
        for (uint256 i = 0; i < approvedOwners.length; i++) {
            if (approvedOwners[i] == msgOwner) {
                return true;
            }
        }
        return false;
    }

    function getLatestTxIndex() external view returns (uint256) {
        return s_latestTxIndex;
    }

    function getMinApproval() external view returns (uint256) {
        return s_minApproval;
    }

    function getIsExistByTxIndex(uint256 txIndex) external view returns (bool) {
        return s_txRecords[txIndex].isExist;
    }

    function getApprovedOwnersByTxIndex(
        uint256 txIndex
    ) external view returns (address[] memory) {
        return s_txRecords[txIndex].s_approvedOwners;
    }

    function getTargetAddressByTxIndex(
        uint256 txIndex
    ) external view returns (address) {
        return s_txRecords[txIndex].s_targetAddress;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    modifier isTxIndexExists(uint256 txIndex) {
        if (!s_txRecords[txIndex].isExist) {
            revert MultiSigWallet__NoTxIndex();
        }
        _;
    }

    modifier isOwner() {
        bool isOwnerExisted = false;
        for (uint i = 0; i < s_owners.length; i++) {
            //TODO: this should be optimized for gas
            if (msg.sender == s_owners[i]) {
                isOwnerExisted = true;
            }
        }
        if (!isOwnerExisted) {
            revert MultiSigWallet__NotOwner();
        }
        _;
    }
}
