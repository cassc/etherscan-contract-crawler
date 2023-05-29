import '@openzeppelin/contracts/access/Ownable.sol';
import './merkle/MerkleProof.sol';
import './interfaces/IERC20.sol';
import './ReentrancyGuard.sol';
import './ERC721A.sol';

pragma solidity ^0.8.6;

/*
    .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .-----------------. .----------------. 
    | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
    | |     ______   | || |      __      | || |  _______     | || |  _________   | || |     ____     | || |     ____     | || | ____  _____  | || |    _______   | |
    | |   .' ___  |  | || |     /  \     | || | |_   __ \    | || | |  _   _  |  | || |   .'    `.   | || |   .'    `.   | || ||_   \|_   _| | || |   /  ___  |  | |
    | |  / .'   \_|  | || |    / /\ \    | || |   | |__) |   | || | |_/ | | \_|  | || |  /  .--.  \  | || |  /  .--.  \  | || |  |   \ | |   | || |  |  (__ \_|  | |
    | |  | |         | || |   / ____ \   | || |   |  __ /    | || |     | |      | || |  | |    | |  | || |  | |    | |  | || |  | |\ \| |   | || |   '.___`-.   | |
    | |  \ `.___.'\  | || | _/ /    \ \_ | || |  _| |  \ \_  | || |    _| |_     | || |  \  `--'  /  | || |  \  `--'  /  | || | _| |_\   |_  | || |  |`\____) |  | |
    | |   `._____.'  | || ||____|  |____|| || | |____| |___| | || |   |_____|    | || |   `.____.'   | || |   `.____.'   | || ||_____|\____| | || |  |_______.'  | |
    | |              | || |              | || |              | || |              | || |              | || |              | || |              | || |              | |
    | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
    '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'                                                                                                                                                      
*/
contract Cartoons is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    
    uint256 public rootMintAmt; // Mints allocated from whitelist mint for each whitelisted address
    uint256 public pubMintMaxPerTx = 1; // Max mint per transaction for public mint
    uint256 public constant MAX_SUPPLY = 7777;  // Max supply allowed to be minted
    uint256 public totalReserved = 125; // total reserved amount to be minted by team + community wallet
    uint256 public itemPrice = 0.07 ether;  // Mint price
    bytes32 public root;    // Merkle root
    string public baseURI = 'https://gateway.pinata.cloud/ipfs/Qmbh34FKCmPcyA7xN73aujqnFhtYe4Erb5mGxvYjzPfYwF/'; // Base URI for tokenURI
    bool public isWhitelistActive;  // Access modifier for whitelist mint function
    bool public isPublicMintActive; // Access modifier for public mint function
    mapping (address=>uint256) reservations;    // Mapping tracks reservation mints (250 total reserved)
    mapping (address=>uint256) share; // Mapping tracks share amounts for withdraw 1000 = 100% so we can handle 1 decimal place

    constructor (bytes32 _root, uint256 _rootMintAmt) ERC721A("Cartoons", "TOON") {
        root = _root;
        rootMintAmt = _rootMintAmt;

        reservations[0x1A0cAAb1AdDdbB12dd61B7f7873c69C18f80AACf] = 25;
        reservations[0xED96E702e654343297D5c56E49C4de4f882f8f8B] = 25;
        reservations[0x0515c23D04B3C078e40363B9b3142303004F343c] = 25;
        reservations[0x19F32B6D6912023c47BC0DF991d80CAAB52620a3] = 25;
        reservations[0xFC56e522504348833BCE63a6c15101d28E9BC1c2] = 25;

        share[0x1A0cAAb1AdDdbB12dd61B7f7873c69C18f80AACf] = 225;
        share[0xED96E702e654343297D5c56E49C4de4f882f8f8B] = 225;
        share[0x0515c23D04B3C078e40363B9b3142303004F343c] = 200;
        share[0x19F32B6D6912023c47BC0DF991d80CAAB52620a3] = 125;
        share[0xFC56e522504348833BCE63a6c15101d28E9BC1c2] = 75;
        share[0x7f7602CFba48a032247e403E551886b8A9ea7267] = 10;
        share[0xbEB82e72F032631E6B3FF0b5Fa04aceA1D6bC0eb] = 140;

        transferOwnership(address(0xbEB82e72F032631E6B3FF0b5Fa04aceA1D6bC0eb));
    }

    /*
        Mint for Whitelisted Addresses - Reentrancy Guarded
        _proof - bytes32 array to verify hash of msg.sender(leaf) is contained in merkle tree
        _amt - uint256 specifies amount to mint (must be no greater than rootMintAmt)
    */
    function whitelistMint(bytes32[] calldata _proof, uint256 _amt) external payable nonReentrant {
        require(totalSupply() + _amt <= MAX_SUPPLY - totalReserved, "Mint Amount Exceeds Total Allowed Mints");
        require(msg.sender == tx.origin, "Minting from Contract not Allowed");
        require(isWhitelistActive, "Cartoons Whitelist Mint Not Active");
        uint64 newClaimTotal = _getAux(msg.sender) + uint64(_amt);
        require(newClaimTotal <= rootMintAmt, "Requested Claim Amount Invalid");
        require(itemPrice * _amt == msg.value,  "Incorrect Payment");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof,root,leaf), "Invalid Proof/Root/Leaf");

        _setAux(msg.sender, newClaimTotal);

        _safeMint(msg.sender, _amt);
    }

    /*
        Public Mint - Reentrancy Guarded
        _amt - uint256 amount to mint
    */
    function publicMint(uint256 _amt) external payable nonReentrant {
        require(totalSupply() + _amt <= MAX_SUPPLY - totalReserved, "Mint Amount Exceeds Total Allowed Mints");
        require(msg.sender == tx.origin, "Minting from Contract not Allowed");
        require(isPublicMintActive, "Cartoons Public Mint Not Active");
        require(_amt <= pubMintMaxPerTx, "Requested Mint Amount Exceeds Limit Per Tx");
        require(itemPrice * _amt == msg.value,  "Incorrect Payment");

        _safeMint(msg.sender, _amt);
    }

    /*
        Reserved Team Mint, 250 Total - Reentrancy Guarded
        _amt - uint256 amount to mint
    */
    function reservationMint(uint256 _amt) external nonReentrant {
        uint256 amtReserved = reservations[msg.sender];
        require(totalSupply() + _amt <= MAX_SUPPLY,"Requested Amount Exceeds Total Supply");
        require(amtReserved >= _amt, "No Reservation for requested amount");
        require(amtReserved <= totalReserved, "Amount Exceeds Total Reserved");
        reservations[msg.sender] -= _amt;
        totalReserved -= _amt;

        _safeMint(msg.sender, _amt);
    }

    /*
        SETTORS - onlyOwner access
    */

    /* 
        Access modifier for whitelist mint function
        _val - TRUE for active / FALSE for inactive mint
    */
    function setWhitelistMintActive(bool _val) external onlyOwner {
        isWhitelistActive = _val;
    }

    /* 
        Access modifier for public mint function
        _val - TRUE for active / FALSE for inactive mint
    */
    function setPublicMintActive(bool _val) external onlyOwner {
        isPublicMintActive = _val;
    }

    /*
        Plant new merkle root to replace whitelist
        _root - bytes32 value of new merkle root
        _amt - uint256 amount each whitelisted address can mint
    */

    function plantNewRoot(bytes32 _root, uint256 _amt) external onlyOwner {
        require(!isWhitelistActive, "Whitelist Minting Not Disabled");
        root = _root;
        rootMintAmt = _amt;
    }

    /*
        Sets new base URI for Cartoons NFT as _uri
        _uri - string value to be new base URI
    */
    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    /*
        Sets new mint price
        _price - uint256 value to be new price
    */
    function setItemPrice(uint256 _price) external onlyOwner {
		itemPrice = _price;
	}

    /*
        Sets new max mint amount per transaction
        _amount - uint256 value to be new max mint amount per transaction
    */
    function setMaxMintPerTx(uint256 _amt) external onlyOwner {
		pubMintMaxPerTx = _amt;
	}

    /*
        GETTORS - view functions
    */

    /*
        Getter function returns how many whitelist mints a specified _user has remaining for current merkle root
        _proof - bytes32 array used to verify that _user is a whitelisted address
        _user - address to check remaining mints for
        amount - uint256 RETURN value that specifies number of remaining mints
    */
    function getAllowedMintAmount(bytes32[] calldata _proof, address _user) public view returns (uint256 amount) {
        bytes32 leaf = keccak256(abi.encodePacked(_user));
        amount = MerkleProof.verify(_proof,root,leaf) ? (rootMintAmt - _getAux(_user)) : 0;
    }

    /*
        Returns mint price
    */
    function getItemPrice() public view returns (uint256) {
		return itemPrice;
	}

    /*
        Returns baseURI string value
    */
    function _baseURI() internal view override returns (string memory){
        return baseURI;
    }

    /*
        Returns tokenURI for specified _tokenID
    */
    function tokenURI(uint256 _tokenID) public view virtual override returns (string memory) {
        require(_exists(_tokenID), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(_baseURI(), _tokenID.toString(), ".json")) : "";
    }
    
    /*
        Utility Functions - onlyOwner access
    */

    /*
        Transfers ETH from this contract to predesignated addresses
    */
    function withdrawEth() public onlyOwner nonReentrant {
        uint256 total = address(this).balance;
        uint256 amt1 = total*share[0x1A0cAAb1AdDdbB12dd61B7f7873c69C18f80AACf]/1000;
        uint256 amt2 = total*share[0xED96E702e654343297D5c56E49C4de4f882f8f8B]/1000;
        uint256 amt3 = total*share[0x0515c23D04B3C078e40363B9b3142303004F343c]/1000;
        uint256 amt4 = total*share[0x19F32B6D6912023c47BC0DF991d80CAAB52620a3]/1000;
        uint256 amt5 = total*share[0xFC56e522504348833BCE63a6c15101d28E9BC1c2]/1000;
        uint256 amt6 = total*share[0x7f7602CFba48a032247e403E551886b8A9ea7267]/1000;
        uint256 amt7 = total*share[0xbEB82e72F032631E6B3FF0b5Fa04aceA1D6bC0eb]/1000;

        require(payable(0x1A0cAAb1AdDdbB12dd61B7f7873c69C18f80AACf).send(amt1));
        require(payable(0xED96E702e654343297D5c56E49C4de4f882f8f8B).send(amt2));
        require(payable(0x0515c23D04B3C078e40363B9b3142303004F343c).send(amt3));
        require(payable(0x19F32B6D6912023c47BC0DF991d80CAAB52620a3).send(amt4));
        require(payable(0xFC56e522504348833BCE63a6c15101d28E9BC1c2).send(amt5));
        require(payable(0x7f7602CFba48a032247e403E551886b8A9ea7267).send(amt6));
        require(payable(0xbEB82e72F032631E6B3FF0b5Fa04aceA1D6bC0eb).send(amt7));
    }

    /*
        Rescue any ERC-20 tokens that are sent to this contract mistakenly
    */
    function withdrawToken(IERC20 _token, uint256 _amount) public onlyOwner {
        _token.transferFrom(address(this), owner(), _amount);
    }
}