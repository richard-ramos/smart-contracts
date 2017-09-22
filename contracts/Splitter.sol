pragma solidity ^0.4.6;

contract Splitter {
    
    address owner;
    
    mapping(address => uint) balance;
    
    modifier restricted() {
        if (msg.sender == owner) _;
    }
    
    
    function Splitter() {
        owner = msg.sender;
    }
	
    event LogSplit(address sender, address rec1, address rec2, uint amount);
    event LogWithdraw(address to, bool success);
    event LogKillSwitch(address sender);
    
    function split(address rec1, address rec2) 
        public 
        payable 
        returns(bool) {
        
        require(msg.value > 0);
        
        balance[rec1] += msg.value / 2;
        balance[rec2] += msg.value / 2;
        
        if(msg.value % 2 == 1){
            balance[msg.sender] += 1;
        }
        
        LogSplit(msg.sender, rec1, rec2, msg.value);
		
        return true;
    }
    
    
    function getBalance(address rec)
        public
        constant
        returns(uint) {
        return balance[rec];
    }
    
    
    function withdraw()
        public 
        returns(bool) {

        uint amount = balance[msg.sender];

        require(amount > 0);
        
		balance[msg.sender] = 0;
		
		LogWithdraw(msg.sender, true);
		
		if(!msg.sender.send(amount)) throw;
		
		return true;
    }
    
    
    function killSwitch() 
        public
        restricted {
        selfdestruct(owner);
        LogKillSwitch(msg.sender);
    }
    
}