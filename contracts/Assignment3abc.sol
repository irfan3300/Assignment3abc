// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns(uint256);
    function transfer(address recepint, uint256 amount) external returns(bool);
    function approve(address spender, uint256 amount) external returns(bool);
    function allowance(address recepint, address spender) external view returns(uint256);
    function transferFrom(address from, address to, uint amount) external returns(bool);
    function totalSupply() external view returns(uint256);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed from, address indexed to, uint256 amount);
    event _Transfer(address indexed from,  uint256 amount);
}

contract ERC20 is IERC20 {
    
    mapping (address => uint256) private balances;
    mapping (address => mapping(address => uint256)) private allowed;
    uint256 Supply;
    address owner1;
    uint256 priceToken = 100;
    uint256 capToken ; // assignment 3b: part 1
    uint mintedOn;    // assignment 3b: part 2
    
    
    constructor() {
        Supply = 100000*2;
        owner1 = msg.sender;
        balances[owner1] = Supply;
        capToken = Supply * 2 ; // assignment 3b: part 1
        
    }
    
    //................assignment 3b: part: 1 ...........................
     function mint(address account, uint256 amount)  external virtual {
        uint256 _Supply = Supply + amount;
        require (msg.sender == owner1, "you are not authorized");
        require(account != address(0), " unauthentic minting address");
        require(_Supply <= capToken, " Maximum Token cap is breached. ");
        
        Supply += amount;
        balances[account] += amount;
         mintedOn = block.timestamp;  // assignment 3b: part 2
        
        
        emit Transfer(address(0), account, amount);

    }
    //....................................................................
    
    //.........................assignment 3b: part:2.......................
    modifier transferAfterMonth(){
        uint256 transferOn = 3629543 +  mintedOn ; 
        require(block.timestamp > transferOn && mintedOn > 0,"ERROR: Wait: Transfer date not reached  ");
        _;
    }  
    
    address[] tempEmployeeSalaryArr;
    mapping(address => uint256) temporaryStay; // it will hold balances for 30 days
    
    // issueSalary function will issue Salary to the employee but will not credit to his account. the salary will 
    // stay in a mapping for a specified time before being credited to the specific account
    
     function issueSalary(address recepint, uint256 amount)public  returns(bool){
        require(balances[msg.sender] >= amount, "you dont have enogh toekns");
        require(msg.sender != address(0) && recepint != address(0));
        require(amount > 0, "Toeken should be greater than 0");
        balances[msg.sender] -= amount; 
        temporaryStay[recepint] += amount;
        tempEmployeeSalaryArr.push(recepint);
        return true;
    }
    
    // creditSalary will credit the salary to the account of employee after one month.
    function creditSalary() public  transferAfterMonth() returns(bool){
        for(uint i=0; i < tempEmployeeSalaryArr.length; i++){
        balances[tempEmployeeSalaryArr[i]] += temporaryStay[tempEmployeeSalaryArr[i]];
        }
        return true;
        
        
    }
    
    //........................................................................
    
    
    function totalSupply() external override view returns(uint256) {
        return Supply;
    }
    
    function balanceOf(address account) external override view returns(uint256) {
        return balances[account];
    }
    
    function purchaseTokens() public payable  {
        require(msg.sender != owner1, "Owner cannot purchase tokens");
        require(msg.value >= 1 ether, "Value should be in ethers");
        require(msg.sender != address(0));
        balances[msg.sender] += (msg.value / (10**18)) * priceToken; //1 ether = 100 tokens
        balances[owner1] -= (msg.value / (10 **18)) * priceToken;
    }
    
    function adjustTokenPrice(uint newPrice) public {
        priceToken = newPrice; //1 ether = new price of tokens
    }
    
    function transfer(address recepint, uint256 amount) public override returns(bool) {
        require(balances[msg.sender] >= amount, "you dont have enogh toekns");
        require(msg.sender != address(0) && recepint != address(0));
        require(amount > 0, "Toeken should be greater than 0");
        balances[msg.sender] -= amount;
        balances[recepint] += amount;
        emit Transfer(msg.sender, recepint, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public override returns(bool) {
        require(msg.sender != address(0) && spender != address(0));
        require(amount > 0, "Toeken should be greater than 0");
        allowed[msg.sender][spender] += amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function allowance(address approver, address spender) public override view returns(uint256) {
        return allowed[approver][spender];
    }
    function transferFrom(address from, address to, uint amount) public override returns(bool) {
        require(amount <= balances[from] && amount <= allowed[from][msg.sender], "balance Low or not approved");
        require(from != address(0) && to != address(0));
        require(amount > 0, "Toeken should be greater than 0");
        balances[to] += amount;
        balances[from] -= amount;
        allowed[from][msg.sender] -=amount;
        emit Transfer(from, to, amount);
        return true;
    }
    fallback() external payable {
        purchaseTokens();
    }
    receive() external payable{
        
    }
    
    //................................assignment 3c: Part 1-4 .......................................
    address private Delegated;
    uint256 private TokenConversion = 100;
   
    modifier OnlyOwner(address _Sender){
        require (owner1 == _Sender);
        _;
    }
    
    modifier OwnerDelegated(address _Address){
        require (owner1 == _Address || Delegated == _Address);
        _;
    }
    
    function ChangeConversion (uint256 _Rate) public OwnerDelegated(msg.sender){
       
        require(_Rate > 0, "Must enter some value");
        
        TokenConversion = _Rate;
    }
    
    function TransferOwnership(address NextOwner) public OnlyOwner(msg.sender){
        require(NextOwner != address(0), "Wrong address");
        uint256 RemainingTokens = balances[owner1];
        balances[NextOwner] += RemainingTokens;
        balances[owner1] -= RemainingTokens;
        owner1 = NextOwner;
    }
    
    function DelegatePower(address _Delegate) public OnlyOwner(msg.sender){
        require (_Delegate != address(0), "Invalid address");
        Delegated = _Delegate;
    }
    
    function ReturnTokens(uint256 _Tokens) public payable returns(uint256){
        require (balances[msg.sender] >= _Tokens, "You have no balance tokens in your account");
        
        uint256 eth = (_Tokens/TokenConversion)*(10**18);
        balances[owner1] += _Tokens;
        balances[msg.sender] -= _Tokens;
        payable(msg.sender).transfer(eth);
        
        emit _Transfer(msg.sender, eth);
        
        return eth;
        
    }
   
    //...............................................................................................
}