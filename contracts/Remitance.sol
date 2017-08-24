pragma solidity ^0.4.6;

contract Remitance {
    
    address owner;
    
    uint fee;
    
    uint feeBalance;
    
    struct TransactionStruct { 
        address origin; // Alice
        address destination; // Bob
        address thirdParty;
        uint amount;
        uint deadlineBlock;
        bool exists;
        bool hasDeadline;
    }
    
    mapping(bytes32 => TransactionStruct) remitanceBook;

    event LogSetFees(uint newFee);
    event LogWithdrawFees(uint balance, bool success);
    event LogSend(address origin, address destination, address thirdParty, uint deadlineBlock, bytes32 keyHash);
    event LogCollect(bytes32 keyHash, bool success);
    event LogRefund(bytes32 keyHash, bool success);
    event LogKillSwitch();

    modifier restricted() {
        if (msg.sender == owner) _;
    }
    
    function Remitance() {
        owner = msg.sender;
        fee = 200000;
        feeBalance = 0;
    }

    function setFee(uint newFee)
        public
        restricted 
        returns(bool) {
        fee = newFee;
        LogSetFees(newFee);
        return true;
    }
    
    function checkAccumulatedFees()
        public
        constant
        restricted
        returns(uint){
            return feeBalance;
    }
    
    function withdrawAccumulatedFees()
        public
        restricted 
        returns(bool) {
        
        if(owner.send(feeBalance)){
            LogWithdrawFees(feeBalance, true);
            feeBalance = 0;
            return true;
        } else {
            LogWithdrawFees(feeBalance, false);
            return false;
        }
    }
    
    function send(address destination, address thirdParty, uint deadlineBlock, bytes32 pwd1, bytes32 pwd2)
        public 
        payable 
        returns(bool) {
            
            if(int(msg.value) - int(fee) < 0) revert();
            
            bytes32 keyHash = keccak256(pwd1, pwd2);

            require(!remitanceBook[keyHash].exists);

            bool hasDeadline = deadlineBlock > 0;
            
            remitanceBook[keyHash] = TransactionStruct(msg.sender, destination, thirdParty, msg.value - fee, block.number + deadlineBlock, true, hasDeadline);
            
            feeBalance += fee;
            
            LogSend(msg.sender, destination, thirdParty, deadlineBlock, keyHash);
            
            return true;
    }
    
    function checkRemitanceBalance(bytes32 pwd1, bytes32 pwd2)
        constant
        returns(uint){
            bytes32 keyHash = keccak256(pwd1, pwd2);
            
            require(remitanceBook[keyHash].exists && 
                   (remitanceBook[keyHash].thirdParty == msg.sender || msg.sender == owner)
                );
                
            return remitanceBook[keyHash].amount;
    }
    
    function collect(bytes32 pwd1, bytes32 pwd2)
        public 
        returns(bool){
            
        bytes32 keyHash = keccak256(pwd1, pwd2);
        
        require(remitanceBook[keyHash].exists &&  
                remitanceBook[keyHash].thirdParty == msg.sender && 
                remitanceBook[keyHash].amount > 0 
                );
        
         if(remitanceBook[keyHash].destination.send(remitanceBook[keyHash].amount)){
            remitanceBook[keyHash].exists = false;
            LogCollect(keyHash, true);
            return true;
        } else {
            LogCollect(keyHash, false);
            return false;
        }
    }

    function refund(bytes32 pwd1, bytes32 pwd2)
        returns(bool){
            
        bytes32 keyHash = keccak256(pwd1, pwd2);
            
        require(remitanceBook[keyHash].exists && 
                remitanceBook[keyHash].origin == msg.sender && 
                remitanceBook[keyHash].amount > 0
                );
        
        if(remitanceBook[keyHash].hasDeadline){
            require(block.number > remitanceBook[keyHash].deadlineBlock);
        }
        
        if(msg.sender.send(remitanceBook[keyHash].amount)){
            remitanceBook[keyHash].exists = false;
            LogRefund(keyHash, true);
            return true;
        } else {
            LogRefund(keyHash, false);
            return false;
        }
    }
    
    
    function killSwitch() 
        public
        restricted {
        LogKillSwitch();
        suicide(owner);
    }
    
}

