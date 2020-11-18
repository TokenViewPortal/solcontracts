contract TKNV_Request_Accountant {
    using SafeMath for uint256;
    
    address owner;
    address escrowContract;
    Escrow escrow;
    uint64 currentid;
    mapping(address => uint256) balances;
    mapping(uint64 => uint256) requests; //request id to reward
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function setEscrowContract(address ec) public onlyOwner{
        escrowContract = ec;
        escrow = new Escrow(ec);
    }
    
    function deposit() public payable {
       balances[msg.sender].add(msg.value);
    }
    
    function deposit_and_request() public payable {
        
        requests[currentid] = msg.value;
        request(msg.value);
    }
    
    function request(uint256 payment) public {
        balances[msg.sender].sub(payment);
        requests[currentid] = payment;
    }
    
    function respond() public {
        escrow.withdraw(msg.sender);
    }
    
    event Request(address indexed payee);
    event Respond(address indexed responder, uint64 indexed id);
    event Deposit(address indexed user, uint256 amt);
}