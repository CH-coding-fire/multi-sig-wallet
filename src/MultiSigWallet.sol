// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract MultiSigWallet {
    error NoAddress();
    error NotOwner();
    error NoTxIndex();
    error NotEnoughOwnerApproval();
    error txFail();
    error alreadyExecuted();
    error ownerNotInApprovalList();
    address[] private s_owners;
    uint256 private s_minApproval;
    struct TxDetails {
        address s_targetAddress;
        address[] s_approvedOwners;
        bool isExist;
        bool isExecuted;
    }
    mapping(uint256=>TxDetails) private s_txRecords;
    uint256 private s_latestTxIndex;


    constructor(address[] memory ownerAddresses, uint minApproval){
        if(ownerAddresses.length == 0){
            revert NoAddress();
        }
        s_owners = ownerAddresses;
        s_minApproval = minApproval;
        s_latestTxIndex = 0;
        
    }

    function requestTx(address targetAddress) external isOwner returns(uint256){
        s_latestTxIndex++;
        s_txRecords[s_latestTxIndex].s_targetAddress = targetAddress;
        s_txRecords[s_latestTxIndex].s_approvedOwners.push(msg.sender);
        s_txRecords[s_latestTxIndex].isExist = true;
        return s_latestTxIndex;
    }

    function approveTx(uint256 txIndex) external isOwner isTxIndexExists(txIndex) {
        s_txRecords[s_latestTxIndex].s_approvedOwners.push(msg.sender);
    }

    function executeTx(uint256 txIndex) external isOwner isTxIndexExists(txIndex){
        if(s_txRecords[txIndex].isExecuted){
            revert alreadyExecuted();
        }
        s_txRecords[txIndex].s_approvedOwners.length >= s_minApproval;
        (bool success,) = s_txRecords[txIndex].s_targetAddress.call{value: address(this).balance}("");
        if(!success){
            revert txFail();
        }
        s_txRecords[txIndex].isExecuted = true;
    }

    function revokeApproval(uint256 txIndex) external isOwner isTxIndexExists(txIndex) {
    if(!checkOwnerIsInApprovedOwner(s_txRecords[txIndex].s_approvedOwners, msg.sender)) {
        revert ownerNotInApprovalList();
    }

    // Directly modify the storage array
    address[] storage approvedOwners = s_txRecords[txIndex].s_approvedOwners;

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

    function checkOwnerIsInApprovedOwner(address[] memory approvedOwners, address msgOwner) private returns(bool){
        for(uint256 i = 0; i<approvedOwners.length; i++){
             if(approvedOwners[i] == msgOwner){
                return true;
             }
        }
        return false;
    }

    modifier isTxIndexExists(uint256 txIndex){
        if(!s_txRecords[txIndex].isExist){
            revert NoTxIndex();
        }
         _;
    }

    modifier isOwner(){
        bool isOwnerExisted = false;
        for(uint i=0; i<s_owners.length; i++){ //TODO: this should be optimized for gas
            if(msg.sender == s_owners[i]){
                isOwnerExisted = true;
            }
        }
        if(!isOwnerExisted){
            revert NotOwner();
        }
        _;
    }
     


   


    
    

    

}
    