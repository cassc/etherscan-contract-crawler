pragma solidity >=0.8.4;

import "./PriceOracle.sol";
import "./BaseRegistrarImplementation.sol";
import "./StringUtils.sol";
import "../resolvers/Resolver.sol";
import {OwnableUpgradeable as Ownable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC165Upgradeable as IERC165} from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import {AddressUpgradeable as Address} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import {IERC721Upgradeable as IERC721} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./StablePriceOracle.sol";

/**
 * @dev A registrar controller for registering and renewing names at fixed cost.
 */
contract BNSRegistrarController is Ownable {
    using StringUtils for *;

    struct TimeLimit{
        uint begin;
        uint end;
    }

    struct  Vars{
        bytes32 leaf;
        bytes32 commitment;    
        uint cost;
        bytes32 label;
        uint256 tokenId;
        uint  expires;
        uint nftValue;
        address owner;
        address resolver;
        address addr;
        uint nameLen;
        IERC721 nft;
        bytes32 nodehash;
    }
 	

    uint public MIN_REGISTRATION_DURATION ;//= 28 days;

    bytes4 constant private INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 constant private COMMITMENT_CONTROLLER_ID = bytes4(
        keccak256("rentPrice(string,uint256)") ^
        keccak256("available(string)") ^
        keccak256("makeCommitment(string,address,bytes32)") ^
        keccak256("commit(bytes32)") ^
        keccak256("register(string,address,uint256,bytes32)") ^
        keccak256("renew(string,uint256)")
    );

    bytes4 constant private COMMITMENT_WITH_CONFIG_CONTROLLER_ID = bytes4(
        keccak256("registerWithConfig(string,address,uint256,bytes32,address,address)") ^
        keccak256("makeCommitmentWithConfig(string,address,bytes32,address,address)")
    );
  
	BaseRegistrarImplementation public base;
    PriceOracle public  prices;
    uint256 public  minCommitmentAge; //60 s
    uint256 public  maxCommitmentAge; //24 hour
    mapping(bytes32=>uint) public commitments;

    mapping(address=>mapping(uint=>uint)) public wlRegedNums; // address =>3 or 4chart =>reged
   // NftWlInfo public nftWlInfo;

    mapping(string=>bool) public reserves;
    mapping(address=>bool) public reserveAdm;
    address gov;  //ethTo
    bytes32  public wlMerkleRoot; 
    mapping(uint=>TimeLimit) public roundTime;// round=> TimeLimit
    
    address public auction;
    mapping(address=>bool) public wlReged;

    mapping (uint => bytes32) public roots; //round =>roots
    mapping(uint => mapping(address=>bool)) public roundWlReged; //round=>address=>reged


    event NameRegistered(string name, bytes32 indexed label, address indexed owner, uint cost, uint expires);
    event NameRenewed(string name, bytes32 indexed label, uint cost, uint expires);
    event NewPriceOracle(address indexed oracle);

	function __BNSRegistrarController_i(
        BaseRegistrarImplementation _base,
        PriceOracle _prices,
        uint256 _minCommitmentAge,
        uint256 _maxCommitmentAge,
        address _gov
        ) public initializer 
    {
        __BNSRegistrarController_init(_base,_prices,_minCommitmentAge,_maxCommitmentAge,_gov);
    }    

    function __BNSRegistrarController_init(
        BaseRegistrarImplementation _base,
        PriceOracle _prices,
        uint256 _minCommitmentAge,
        uint256 _maxCommitmentAge,
        address _gov
        ) internal onlyInitializing 
    {
        __Ownable_init();
        __BNSRegistrarController_init_unchained(_base,_prices,_minCommitmentAge,_maxCommitmentAge,_gov);
    }

    function __BNSRegistrarController_init_unchained(
        BaseRegistrarImplementation _base,
        PriceOracle _prices,
        uint256 _minCommitmentAge,
        uint256 _maxCommitmentAge,
        address _gov) internal onlyInitializing {
       
        require(_maxCommitmentAge > _minCommitmentAge);
		MIN_REGISTRATION_DURATION =365 days;
        base = _base;
        prices = _prices;
        minCommitmentAge = _minCommitmentAge;
        maxCommitmentAge = _maxCommitmentAge;
        gov = _gov;
    }

	

 


    function rentPrice(string memory name, uint duration) view public returns(uint) {
        bytes32 hash = keccak256(bytes(name));
        return prices.price(name, base.nameExpires(uint256(hash)), duration);
    }


    function valid(string memory name) public pure returns (bool) {
        // check unicode rune count, if rune count is >=3, byte length must be >=3.
        if (name.strlen() < 3) {
            return false;
        }
        bytes memory nb = bytes(name);
        // zero width for /u200b /u200c /u200d and U+FEFF
        for (uint256 i; i < nb.length - 2; i++) {
            if (bytes1(nb[i]) == 0xe2 && bytes1(nb[i + 1]) == 0x80) {
                if (
                    bytes1(nb[i + 2]) == 0x8b ||
                    bytes1(nb[i + 2]) == 0x8c ||
                    bytes1(nb[i + 2]) == 0x8d
                ) {
                    return false;
                }
            } else if (bytes1(nb[i]) == 0xef) {
                if (bytes1(nb[i + 1]) == 0xbb && bytes1(nb[i + 2]) == 0xbf)
                    return false;
            }
        }
        return true;
    }


    function setReserves(string [] calldata names,bool[] calldata isReserves) public onlyOwner {
        require(names.length == isReserves.length,"len not match");
        for (uint i=0;i<names.length;i++){
            reserves[names[i]] = isReserves[i];
        }
    }
    function setReserveAdm(address acct,bool isAdm) public onlyOwner {
        reserveAdm[acct] = isAdm;
    }

    function setGov(address _gov) public onlyOwner {
        gov = _gov;
    }

    function setAuction(address _auction) public onlyOwner {
        auction = _auction;
    }


    function setDur(uint _day) public onlyOwner {
        MIN_REGISTRATION_DURATION = 86400*_day ;
    }

    function setRoot(uint round,bytes32 _root) public onlyOwner {
        roots[round] = _root;
    }


    function setTime(uint _round,uint _begin,uint _end) public onlyOwner {
        roundTime[_round] = TimeLimit(_begin,_end);
    }

    function availableWithReserve(string memory name,address acct)public view returns(bool) {
        return (available(name) && (!isLimit(name,acct)));
    }

    function isLimit(string memory name,address acct) public view returns(bool) {
        if(reserveAdm[acct])
            return false;
        if (reserves[name])
            return true;
        return false;
    }

    function available(string memory name) public view returns(bool) {
        bytes32 label = keccak256(bytes(name));
        return valid(name) && base.available(uint256(label));
    }

    function makeCommitment(string memory name, address owner, bytes32 secret) pure public returns(bytes32) {
        return makeCommitmentWithConfig(name, owner, secret, address(0), address(0));
    }

    function makeCommitmentWithConfig(string memory name, address owner, bytes32 secret, address resolver, address addr) pure public returns(bytes32) {
        bytes32 label = keccak256(bytes(name));
        if (resolver == address(0) && addr == address(0)) {
            return keccak256(abi.encodePacked(label, owner, secret));
        }
        require(resolver != address(0));
        return keccak256(abi.encodePacked(label, owner, resolver, addr, secret));
    }

    function commit(bytes32 commitment) public {
        require(commitments[commitment] + maxCommitmentAge < block.timestamp);
        commitments[commitment] = block.timestamp;
    }

    function timeBegin(uint begin,uint end,bool onlyBegin) public view returns (bool){
        if (reserveAdm[msg.sender])
            return true;
        if (onlyBegin)    {
            if (block.timestamp >=begin)
                return true;
        }
        else{
            if ((block.timestamp >=begin)&&(block.timestamp <=end))
                return true;
        }
        return false;
    }

   /* function renewAdm(string calldata name, uint duration) external payable {
        require(reserveAdm[msg.sender],"only adm");      
        bytes32 label = keccak256(bytes(name));
        uint expires = base.renew(uint256(label), duration);
        emit NameRenewed(name, label, 0, expires);
    }

    function registerWithConfigAdm(string memory name, address resolver) public payable {
        //bytes32 commitment = makeCommitmentWithConfig(name, owner, secret, resolver, addr);
        //uint cost = _consumeCommitment(name, duration, commitment);
        require(reserveAdm[msg.sender],"only adm");      
        uint duration = 100*(365 days);
        address owner = msg.sender;
        address addr = msg.sender;

        bytes32 label = keccak256(bytes(name));
        uint256 tokenId = uint256(label);

        uint expires;
        if(resolver != address(0)) {
            // Set this contract as the (temporary) owner, giving it
            // permission to set up the resolver.
            expires = base.registerWithName(tokenId, address(this), duration,name);

            // The nodehash of this label
            bytes32 nodehash = keccak256(abi.encodePacked(base.baseNode(), label));

            // Set the resolver
            base.bns().setResolver(nodehash, resolver);

            // Configure the resolver
            if (addr != address(0)) {
                Resolver(resolver).setAddr(nodehash, addr);
            }

            // Now transfer full ownership to the expeceted owner
            base.reclaim(tokenId, owner);
            base.transferFrom(address(this), owner, tokenId);
        } else {
            require(addr == address(0));
            expires = base.registerWithName(tokenId, owner, duration,name);
        }

        emit NameRegistered(name, label, owner, 0, expires);

    }*/



   /* function wlRegister(string calldata name, address owner, uint duration, bytes32 secret,uint wlNum,uint[] calldata tokenIds,bytes32[] calldata _merkleProof) external payable {
        Vars memory vars;
        vars.leaf = keccak256(abi.encodePacked(msg.sender,wlNum));
        require(MerkleProofUpgradeable.verify(_merkleProof, nftWlInfo.wlMerkleRoot, vars.leaf),"Invalid Proof." );
        uint nameLen = name.strlen();
        require(wlRegedNums[msg.sender][nameLen]<wlNum,"reached wlNum");
        wlRegedNums[msg.sender][nameLen]++;
        IERC721 nft = IERC721(nftWlInfo.passNFT);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId_ = tokenIds[i];
            require(msg.sender == nft.ownerOf(tokenId_), "Not owner");
            nft.transferFrom(msg.sender, nftWlInfo.nftTo, tokenId_);
        }
   
        vars.commitment = makeCommitmentWithConfig(name, owner, secret, address(0), address(0));
        vars.cost = _consumeCommitment(name, duration, vars.commitment,tokenIds.length);

        vars.label = keccak256(bytes(name));
        vars.tokenId = uint256(vars.label);

        vars.expires = base.registerWithName(vars.tokenId, owner, duration,name);

        emit NameRegistered(name, vars.label, owner, vars.cost, vars.expires);

        vars.nftValue = passToEth()*tokenIds.length; 
        if(vars.nftValue >= vars.cost)
           return;

        // Refund any extra payment
        if((msg.value+vars.nftValue) > vars.cost) {
            payable(msg.sender).transfer(msg.value+vars.nftValue - vars.cost);
        }
        payable(gov).transfer( vars.cost-vars.nftValue);
    }*/

    /*function register(string calldata name, address owner, uint duration, bytes32 secret) external payable {
        registerWithConfig(name, owner, duration, secret, address(0), address(0));
    }*/

   /* function checkWl(address user,string calldata name,uint duration,bytes32[] calldata _merkleProof) public view returns(bool){
        bytes32 leaf = keccak256(abi.encodePacked(user,name,duration));
        return MerkleProofUpgradeable.verify(_merkleProof, wlMerkleRoot, leaf);
    }*/

    function checkWl(address user,bytes32[] calldata _merkleProof) public view returns(bool){
        bytes32 leaf = keccak256(abi.encodePacked(user));
        return MerkleProofUpgradeable.verify(_merkleProof, wlMerkleRoot, leaf);
    }


    function getPrice(string calldata name) public pure returns (uint retPrice){
        uint len = name.strlen();
        if (len ==3)
            retPrice = 1 ether;
        else if (len ==4)
            retPrice = 0.2 ether;
        else 
            retPrice =0.01 ether;
    }
    //round 1 
    function bidRegisterWithConfig(string calldata name, address[] calldata  ora ) external  { // ora:address owner,address resolver, address addr
        require(timeBegin(roundTime[1].begin,roundTime[1].end,false),"time limit");
        require(available(name),"name unavailable");
        UserPrice memory userPrice = IAuction(auction).nameHighPrice(name);
        require(userPrice.user==msg.sender,"You are not the name's bid winner");
        uint duration = 100*(365 days);
        Vars memory vars;
        vars.owner = ora[0];
        vars.resolver = ora[1];
        vars.addr = ora[2];
        vars.cost = userPrice.price;
        vars.label = keccak256(bytes(name));
        vars.tokenId = uint256(vars.label);

        if(vars.resolver != address(0)) {
            // Set this contract as the (temporary) owner, giving it
            // permission to set up the resolver.
            vars.expires = base.registerWithName(vars.tokenId, address(this), duration,name);

            // The nodehash of this label
            bytes32 nodehash = keccak256(abi.encodePacked(base.baseNode(), vars.label));

            // Set the resolver
            base.bns().setResolver(nodehash, vars.resolver);

            // Configure the resolver
            if (vars.addr != address(0)) {
                Resolver(vars.resolver).setAddr(nodehash, vars.addr);
            }

            // Now transfer full ownership to the expeceted owner
            base.reclaim(vars.tokenId, vars.owner);
            base.transferFrom(address(this), vars.owner, vars.tokenId);
        } else {
            require(vars.addr == address(0));
            vars.expires = base.registerWithName(vars.tokenId, vars.owner, duration,name);
        }
        emit NameRegistered(name, vars.label, vars.owner, vars.cost, vars.expires);
    }

    function isBided(string calldata name) public view returns(bool){
        UserPrice memory userPrice = IAuction(auction).nameHighPrice(name);
        if (userPrice.price>0)
            return true;
        else
            return false;
    }

    //round 2
    function wlRegisterWithConfig(string calldata name,bytes32[] calldata _merkleProof, address[] calldata  ora ) external payable { // ora:address owner,address resolver, address addr
        require(timeBegin(roundTime[2].begin,roundTime[2].end,false),"time limit");
        require(available(name),"name unavailable");
        require(!isBided(name),"name bided");
        //require(!isLimit(name,msg.sender),"limit"); //reserve
        require(!roundWlReged[2][msg.sender],"reged!");
        roundWlReged[2][msg.sender] = true;
        uint duration = 100*(365 days);
        Vars memory vars;
        vars.leaf = keccak256(abi.encodePacked(msg.sender));
        if (!reserveAdm[msg.sender])
            require(MerkleProofUpgradeable.verify(_merkleProof, roots[2], vars.leaf),"Invalid Proof." );
        vars.owner = ora[0];
        vars.resolver = ora[1];
        vars.addr = ora[2];
        //vars.commitment = makeCommitmentWithConfig(name, vars.owner, secret, vars.resolver, vars.addr);
        //vars.cost = _consumeCommitment(name, duration, vars.commitment,1e18);
        vars.cost = getPrice(name);
        require(msg.value >= vars.cost,"eth insufficient");
        vars.label = keccak256(bytes(name));
        vars.tokenId = uint256(vars.label);

        if(vars.resolver != address(0)) {
            // Set this contract as the (temporary) owner, giving it
            // permission to set up the resolver.
            vars.expires = base.registerWithName(vars.tokenId, address(this), duration,name);

            // The nodehash of this label
            bytes32 nodehash = keccak256(abi.encodePacked(base.baseNode(), vars.label));

            // Set the resolver
            base.bns().setResolver(nodehash, vars.resolver);

            // Configure the resolver
            if (vars.addr != address(0)) {
                Resolver(vars.resolver).setAddr(nodehash, vars.addr);
            }

            // Now transfer full ownership to the expeceted owner
            base.reclaim(vars.tokenId, vars.owner);
            base.transferFrom(address(this), vars.owner, vars.tokenId);
        } else {
            require(vars.addr == address(0));
            vars.expires = base.registerWithName(vars.tokenId, vars.owner, duration,name);
        }


        emit NameRegistered(name, vars.label, vars.owner, vars.cost, vars.expires);

        // Refund any extra payment
        if(msg.value > vars.cost) {
            payable(msg.sender).transfer(msg.value - vars.cost);
        }
        //(bool success,) = payable(gov).call{value:(vars.cost)}("");
        //require(success,"send bnb faild");

    }

    //round 3  root 3
    function wlFreeRegisterWithConfig(string calldata name,bytes32[] calldata _merkleProof, address[] calldata  ora ) external payable { // ora:address owner,address resolver, address addr
        require(timeBegin(roundTime[3].begin,roundTime[3].end,false),"time limit");
        require(available(name),"name unavailable");
        require(!isBided(name),"name bided");
        //require(!isLimit(name,msg.sender),"limit"); //reserve
        require(!roundWlReged[3][msg.sender],"reged!");
        roundWlReged[3][msg.sender] = true;
        uint duration = 100*(365 days);
        Vars memory vars;
        vars.leaf = keccak256(abi.encodePacked(msg.sender));
        if (!reserveAdm[msg.sender])
            require(MerkleProofUpgradeable.verify(_merkleProof, roots[3], vars.leaf),"Invalid Proof." );
        vars.owner = ora[0];
        vars.resolver = ora[1];
        vars.addr = ora[2];
        //vars.commitment = makeCommitmentWithConfig(name, vars.owner, secret, vars.resolver, vars.addr);
        //vars.cost = _consumeCommitment(name, duration, vars.commitment,1e18);
        vars.cost = 0;//getPrice(name);
        //require(msg.value >= vars.cost,"eth insufficient");
        vars.label = keccak256(bytes(name));
        vars.tokenId = uint256(vars.label);

        if(vars.resolver != address(0)) {
            // Set this contract as the (temporary) owner, giving it
            // permission to set up the resolver.
            vars.expires = base.registerWithName(vars.tokenId, address(this), duration,name);

            // The nodehash of this label
            bytes32 nodehash = keccak256(abi.encodePacked(base.baseNode(), vars.label));

            // Set the resolver
            base.bns().setResolver(nodehash, vars.resolver);

            // Configure the resolver
            if (vars.addr != address(0)) {
                Resolver(vars.resolver).setAddr(nodehash, vars.addr);
            }

            // Now transfer full ownership to the expeceted owner
            base.reclaim(vars.tokenId, vars.owner);
            base.transferFrom(address(this), vars.owner, vars.tokenId);
        } else {
            require(vars.addr == address(0));
            vars.expires = base.registerWithName(vars.tokenId, vars.owner, duration,name);
        }


        emit NameRegistered(name, vars.label, vars.owner, vars.cost, vars.expires);

        // Refund any extra payment
        if(msg.value > vars.cost) {
            payable(msg.sender).transfer(msg.value - vars.cost);
        }
        //(bool success,) = payable(gov).call{value:(vars.cost)}("");
        //require(success,"send bnb faild");

    }

    //round 4 
    function pubRegisterWithConfig(string calldata name, address[] calldata  ora ) external payable { // ora:address owner,address resolver, address addr
        require(timeBegin(roundTime[4].begin,roundTime[4].end,false),"time limit");
        require(available(name),"name unavailable");
        require(!isBided(name),"name bided");
        //require(!isLimit(name,msg.sender),"limit"); //reserve
        uint duration = 100*(365 days);
        Vars memory vars;
        vars.owner = ora[0];
        vars.resolver = ora[1];
        vars.addr = ora[2];
        //vars.commitment = makeCommitmentWithConfig(name, vars.owner, secret, vars.resolver, vars.addr);
        //vars.cost = _consumeCommitment(name, duration, vars.commitment,1e18);
        vars.cost = getPrice(name);
        require(msg.value >= vars.cost,"eth insufficient");
        vars.label = keccak256(bytes(name));
        vars.tokenId = uint256(vars.label);

        if(vars.resolver != address(0)) {
            // Set this contract as the (temporary) owner, giving it
            // permission to set up the resolver.
            //vars.expires = base.register(vars.tokenId, address(this), duration);
            vars.expires = base.registerWithName(vars.tokenId, address(this), duration,name);
            

            // The nodehash of this label
            bytes32 nodehash = keccak256(abi.encodePacked(base.baseNode(), vars.label));

            // Set the resolver
            base.bns().setResolver(nodehash, vars.resolver);

            // Configure the resolver
            if (vars.addr != address(0)) {
                Resolver(vars.resolver).setAddr(nodehash, vars.addr);
            }

            // Now transfer full ownership to the expeceted owner
            base.reclaim(vars.tokenId, vars.owner);
            base.transferFrom(address(this), vars.owner, vars.tokenId);
        } else {
            require(vars.addr == address(0));
            vars.expires = base.registerWithName(vars.tokenId, vars.owner, duration,name);
        }


        emit NameRegistered(name, vars.label, vars.owner, vars.cost, vars.expires);

        // Refund any extra payment
        if(msg.value > vars.cost) {
            payable(msg.sender).transfer(msg.value - vars.cost);
        }
        //(bool success,) = payable(gov).call{value:(vars.cost)}("");
        //require(success,"send bnb faild");

    }


 
    function renew(string calldata name/*, uint duration*/) external payable {
        uint duration = 100*(365 days);
        uint cost = rentPrice(name, duration);
        require(msg.value >= cost);

        bytes32 label = keccak256(bytes(name));
        uint expires = base.renew(uint256(label), duration);

        if(msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }

        emit NameRenewed(name, label, cost, expires);
        //payable(gov).transfer(cost);
        (bool success,) = payable(gov).call{value:cost}("");
        require(success,"send bnb faild");
    }

    function setPriceOracle(PriceOracle _prices) public onlyOwner {
        prices = _prices;
        emit NewPriceOracle(address(prices));
    }

    function setBase(BaseRegistrarImplementation _base) public onlyOwner {
        base = _base;
    }


    function setConf(uint _minCommitmentAge, uint _maxCommitmentAge) public onlyOwner {
        minCommitmentAge = _minCommitmentAge;
        maxCommitmentAge = _maxCommitmentAge;
    }
    

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);        
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == INTERFACE_META_ID ||
               interfaceID == COMMITMENT_CONTROLLER_ID ||
               interfaceID == COMMITMENT_WITH_CONFIG_CONTROLLER_ID;
    }

    function _consumeCommitment(string memory name, uint duration, bytes32 commitment,uint rate) internal returns (uint256) {
        // Require a valid commitment
        require(commitments[commitment] + minCommitmentAge <= block.timestamp);

        // If the commitment is too old, or the name is registered, stop
        require(commitments[commitment] + maxCommitmentAge > block.timestamp);

        delete(commitments[commitment]);

        uint cost = rentPrice(name, duration)*rate/1e18;
        require(duration >= MIN_REGISTRATION_DURATION);
        require(msg.value >= cost);

        return cost;
    }
}

struct UserPrice{
        address user;
        uint price;
        bool locked;
}

interface IAuction{
    function nameHighPrice(string memory name) external view returns(UserPrice memory);
}