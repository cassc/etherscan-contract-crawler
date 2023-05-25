//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import '@chainlink/contracts/src/v0.8/ChainlinkClient.sol';
import '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";


contract Wait is ERC20, ERC20Burnable, ChainlinkClient, ConfirmedOwner{
    using Chainlink for Chainlink.Request;

    address manager;
    address timeKeeper = 0x20d7acED31E7C947faB0C3aD62C2D426D152C399;
    uint256 public totalSacs = 8;
    bool public minting = true;
    bytes32 private jobId;

    event Reload(
        address _user
    );


    mapping (uint => mapping(address => bool)) public InData;
    mapping (uint => mapping(address => bool)) public Claimed;
    mapping (uint => mapping(address => uint)) public ClaimedAmount;
    mapping(uint => uint) public totalWait;
    mapping(uint => uint) public totalPeople;
    mapping(uint => uint) public mintedPeople;
    mapping(uint => uint) public unclaimedWait;
    mapping(uint => uint) public sacTimes;
    mapping(address => bool) public checked;
    
    constructor() ERC20("Wait", "WAIT")   ConfirmedOwner(msg.sender){
        manager = 0x25B6106149284b0269C44BE6beda5ec59C89753a;
        totalPeople[0] = 55374; //Pulse
        totalPeople[1] = 124815; //PulseX
        totalPeople[2] = 9465; //Liquid Loans
        totalPeople[3] = 230; //Hurricash
        totalPeople[4] = 839; //Genius
        totalPeople[5] = 2937; //Mintra
        totalPeople[6] = 653; //Phiat
        totalPeople[7] = 1241; //Internet Money Dividend

        sacTimes[0] = 1627948800; //Pulse
        sacTimes[1] = 1645660800; //PulseX
        sacTimes[2] = 1647907200; //Liquid Loans
        sacTimes[3] = 1646092800; //Hurricash
        sacTimes[4] = 1654041600; //Genius
        sacTimes[5] = 1647561600; //Mintra
        sacTimes[6] = 1654387200; //Phiat
        sacTimes[7] = 1647734400; //Internet Money Dividend

        setChainlinkToken(0x514910771AF9Ca656af840dff83E8264EcF986CA);
        setChainlinkOracle(0x2e973758d5f319ED4768570182cA601e970ff549);
        jobId = '233eae6ef5c34ad2a0fe2eaed75b5f44';

    }

    modifier manager_function(){
        require(msg.sender==manager,"Only the manager can call this function");
    _;}

    modifier minting_on(){
        require(minting == true,"Minting Wait has been turned off, go claim the unclaimed Wait");
    _;}

    function decimals() public pure override returns (uint8) {
        return 0;
    }

    function checkDatabase(string memory _address) public returns (bytes32 requestId) {
        
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
       
        req.add('address', _address); 
        req.add('path',"bro");
        req.add('path1',"man");


        sendOperatorRequest(req, 0);
    }

    function fulfill(bytes32 _requestId, address user, uint binary) public recordChainlinkFulfillment(_requestId) {
        uint yes = binary;

        emit Reload(user);


        checked[user]=true;
        
        if(yes>=128){
            InData[7][user]=true;
            yes-=128;
        }
        if(yes>=64){
            InData[6][user]=true;
            yes-=64;
        }
        if(yes>=32){
            InData[5][user]=true;
            yes-=32;
        }
        if(yes>=16){
            InData[4][user]=true;
            yes-=16;
        }
        if(yes>=8){
            InData[3][user]=true;
            yes-=8;
        }
        if(yes>=4){
            InData[2][user]=true;
            yes-=4;
        }
        if(yes>=2){
            InData[1][user]=true;
            yes-=2;
        }
        if(yes>=1){
            InData[0][user]=true;
            yes-=1;
        }
        require(yes==0,"Something went wrong here");
    }

    function inDatabase() public view returns(bool[8] memory) {
        return [InData[0][msg.sender], 
        InData[1][msg.sender],
        InData[2][msg.sender],
        InData[3][msg.sender],
        InData[4][msg.sender],
        InData[5][msg.sender],
        InData[6][msg.sender],
        InData[7][msg.sender]];
    }

    function haveClaimed() public view returns(bool[8] memory) {
        return [Claimed[0][msg.sender],
        Claimed[1][msg.sender],
        Claimed[2][msg.sender],
        Claimed[3][msg.sender],
        Claimed[4][msg.sender],
        Claimed[5][msg.sender],
        Claimed[6][msg.sender],
        Claimed[7][msg.sender]];
    }

    function mintableWait(uint sac) public view minting_on returns(uint){

        require(sac < totalSacs, "Not an accurate sacrifice");
        require(InData[sac][msg.sender] == true, "You were not in the specific sacrifice or you need to check!");
        require(Claimed[sac][msg.sender] == false, "You already minted your wait for this sacrifice!");
        
        return (block.timestamp - sacTimes[sac]) / 3600;

    }
    
    function mintWait(uint sac) public minting_on {

        require(sac < totalSacs, "Not an accurate sacrifice");
        require(Claimed[sac][msg.sender] == false, "You already minted your wait for this sacrifice!");
        require(InData[sac][msg.sender] == true, "You were not in this sacrifice or you haven't checked the database yet!");

        Claimed[sac][msg.sender] = true;
        mintedPeople[sac]++;

        uint mintableWait1 = (block.timestamp - sacTimes[sac]) / 3600;
        ClaimedAmount[sac][msg.sender] = mintableWait1;
        totalWait[sac] += mintableWait1;
        _mint(msg.sender, mintableWait1);

    }

    function mintableAllWait() public view minting_on returns (uint[] memory) {
        
        uint[] memory testing = new uint[](8);


        for(uint i; i < totalSacs; i++) {
            if(!Claimed[i][msg.sender] && InData[i][msg.sender]) {
                testing[i] = (block.timestamp - sacTimes[i]) / 3600;
            }
        }

        return testing;

    }

    function hasChecked() public view returns(bool){
        return checked[msg.sender];
    }
    
    function mintAllWait() public minting_on {

        uint mintableWait1 = 0;

        for(uint i; i < totalSacs; i++) {
            if(!Claimed[i][msg.sender] && InData[i][msg.sender]) {
                Claimed[i][msg.sender] = true;
                mintedPeople[i]++;
                ClaimedAmount[i][msg.sender] = (block.timestamp - sacTimes[i]) / 3600;
                totalWait[i] += ClaimedAmount[i][msg.sender];
                mintableWait1 += ClaimedAmount[i][msg.sender];
            }
        }

        _mint(msg.sender, mintableWait1);
        
    }

    function midnightBonus() public manager_function minting_on {

        minting = false;
        uint waitAmount;

        for(uint i; i < totalSacs; i++) {
            unclaimedWait[i] = (totalPeople[i] - mintedPeople[i]) * ((block.timestamp - sacTimes[i]) / 3600) / 2;
            waitAmount += unclaimedWait[i];
        }

        _mint(timeKeeper, waitAmount);
    }

    function mintableUnclaimedWait(uint sac) public view returns (uint waitAmount) {

        require(sac<totalSacs, "not an accurate sacrifice");
        require(!minting, "Minting is still on");
        require(Claimed[sac][msg.sender], "You never claimed your wait or already claimed the unclaimed wait");

        waitAmount = unclaimedWait[sac] * ClaimedAmount[sac][msg.sender] / totalWait[sac];

    }
    
    function mintUnclaimedWait(uint sac) public {

        require(sac<totalSacs, "not an accurate sacrifice");
        require(!minting, "Minting is still on");
        require(Claimed[sac][msg.sender], "You never claimed your wait or already claimed the unclaimed wait");

        Claimed[sac][msg.sender] = false;
        uint waitAmount;
        waitAmount = unclaimedWait[sac] * ClaimedAmount[sac][msg.sender] / totalWait[sac];
        _mint(msg.sender, waitAmount);
        
    }

    function mintableAllUnclaimedWait() public view returns(uint waitAmount) {

        require(!minting, "Minting is still on");

        for(uint i; i < totalSacs; i++) {
            if(Claimed[i][msg.sender]) {
                waitAmount += unclaimedWait[i] * ClaimedAmount[i][msg.sender] / totalWait[i];
            }
        }

    }
    
    function mintAllUnclaimedWait() public {

        require(!minting, "Minting is still on");

        uint waitAmount = 0;
        for(uint i; i < totalSacs; i++) {
            
            if(Claimed[i][msg.sender]) {
                Claimed[i][msg.sender] = false;
                waitAmount += unclaimedWait[i] * ClaimedAmount[i][msg.sender] / totalWait[i];
            }
        }

        _mint(msg.sender, waitAmount);
    }


}