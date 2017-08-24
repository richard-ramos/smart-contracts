pragma solidity ^0.4.6;

contract Remitance {
    
    address owner;
    
    uint fee;
    
    uint feeBalance;
    
    struct TransactionStruct { 
        address origin; // Alice
        address destination; // Carol
        uint amount;
        uint deadlineBlock;
        bool exists;
        bool hasDeadline;
    }
    
    mapping(bytes32 => TransactionStruct) remitanceBook;

    event LogSetFees(uint newFee);
    event LogWithdrawFees(uint balance);
    event LogSend(address origin, address destination, uint deadlineBlock, bytes32 keyHash);
    event LogCollect(bytes32 keyHash);
    event LogRefund(bytes32 keyHash);
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
        
		uint amount = feeBalance;
		feeBalance = 0;
		
		LogWithdrawFees(amount);
		
		if(!owner.send(amount)) revert();
		
        return true;
    }
    
	
	// pwd1 and pwd2 should be hashes created by the client.
    function send(address destination uint deadlineBlock, bytes32 pwd1, bytes32 pwd2)
        public 
        payable 
        returns(bool) {
            
            if(int(msg.value) - int(fee) < 0) revert();
            
            bytes32 keyHash = keccak256(pwd1, pwd2);

            require(!remitanceBook[keyHash].exists);

            bool hasDeadline = deadlineBlock > 0;
            
            remitanceBook[keyHash] = TransactionStruct(msg.sender, destination, msg.value - fee, block.number + deadlineBlock, true, hasDeadline);
            
            feeBalance += fee;
            
            LogSend(msg.sender, destination, deadlineBlock, keyHash);
            
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
                remitanceBook[keyHash].destination == msg.sender && 
                remitanceBook[keyHash].amount > 0 
                );
        
		LogCollect(keyHash);
		
		if(!msg.sender.send(remitanceBook[keyHash].amount)) revert();
		
		return true;
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
        
		LogRefund(keyHash);
		
		if(!msg.sender.send(remitanceBook[keyHash].amount)) revert();
		
		return true;
    }
    
    
    function killSwitch() 
        public
        restricted {
        LogKillSwitch();
        selfdestruct(owner);
    }
    
}

