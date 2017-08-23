pragma solidity ^0.4.6;

contract Remitance {
    
    address owner;
    uint fee;
    
    struct TransactionStruct {
    	// TODO
    }
    
    modifier restricted() {
        if (msg.sender == owner) _;
    }
    
    
    function Remitance() {
        owner = msg.sender;
        fee = 25000;
    }

    function setFee(uint newFee)
    	public
    	returns(bool) {
    	fee = newFee;
    }


    function send(address rec, uint deadline, bytes32 pHash1, bytes32 pHash2)
    	public 
    	payable 
    	returns(bool) {
    		// TODO save exchangeowner (carol)

    }
	
	function collect(bytes32 pHash1, bytes32 pHash2)
		public 
		returns(bool){
			// TODO only exchangeowner can call withdraw abd will send to rec
	}

	function refund()
		returns(bool){

		}
    
    
    function killSwitch() 
        public
        restricted {

//  todo return funds?


        suicide(owner);
        LogKillSwitch();
    }
    
}