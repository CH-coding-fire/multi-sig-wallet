// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract MultiSigWallet {
    error NotOwner();
    error NoTxIndex();
    error NotEnoughOwnerApproval();
    address[] private s_owners;
    mapping(uint=>mapping(address=>bool)) public s_txAndOwnersThatApproved;
    uint256 private s_minApproval;
    mapping(uint256=>address)[] private s_txIndex;

    

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

    function setOwners(address[] memory owners, uint256 minApproval) external {
        s_minApproval = minApproval;
        s_owners = owners;
    }

    function requestTx(address targetAddress) external isOwner returns (uint256){
        uint256 txIndex = s_txIndex.length;
        // Set the targetAddress for the new transaction index
        s_txIndex[txIndex][txIndex] = targetAddress;

        
        s_txAndOwnersThatApproved[txIndex][msg.sender] = true;
        return txIndex;
    }

    function approveTx(uint256 txIndex) external isOwner {
        bool foundTxIndex = false;
        for(uint i=0; i<s_txIndex.length; i++){

        }
        if(!foundTxIndex){
            revert NoTxIndex();
        }
        s_txAndOwnersThatApproved[txIndex][msg.sender] = true;
    }

    function executeTx(uint256 txIndex, address targetAddress) external isOwner {
        uint256 approvedOwnerCount = 0;
        for(uint i=0; i<s_owners.length; i++) {
            if(s_txAndOwnersThatApproved[txIndex][(s_owners[i])]==true){
                approvedOwnerCount++;
            } 
        }
        if(approvedOwnerCount<s_minApproval){
            revert NotEnoughOwnerApproval();
        }
        
    }

    

    

}

//Plan:
//1. Think about how multi sig works
//2. a wallet, need to stored approved signer
//3. It should have following functions: 1. setSigners 2. individualSignersComeSign 3. Send to certain address 4. revoke