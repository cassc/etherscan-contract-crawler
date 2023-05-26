// contracts/cryptoshack.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./base_contracts/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IMulesquad {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract CryptoShack is ERC721, ReentrancyGuard {
    string _baseTokenURI;

    address public owner;

    IMulesquad internal mulesquadContract = IMulesquad(0xa088AC5a19c28c882D71725C268244b233CFFC62);

    uint constant public MAX_SUPPLY = 7200;
    uint constant public mintCost = 0.069 ether;
    uint constant public maxMintPerTx = 3;
    uint public maxPerWallet = 20;

    // external counter instead of ERC721Enumerable:totalSupply()
    uint256 public totalSupply;
    uint256 public publicMinted;

    uint256 public reserveMinted;
    uint256 public teamReserved = 300;

    uint256 public mulesquadClaimed;
    uint256 public mulesquadReserved = 690;

    // more random, rolled on noContracts
    bytes32 private entropySauce;
    uint private NOUNCE;

    // some numbers and trackers type-based
    uint[4][5] private typeToNumbers;
    bytes32[5] private typeToNames;

    // amount of tokens minted by wallet
    mapping(address => uint) private walletToMinted;
    // address to amount of tokens of every type owned
    mapping(address => uint[5]) private addressToTypesOwned;
    // address to last action block number
    mapping(address => uint) private callerToLastBlockAction;
    // map show if mulesquad ID was used to claim token or not
    mapping(uint => bool) private mulesquadIdToClaimed;

    bool public mintAllowed;
    bool public exchangeAllowed;
    bool public claimAllowed;
    bool public revealed;

    constructor() ERC721("CryptoShack", "SHACK") {
        owner=msg.sender;

        typeToNames[0]="gophers";
        typeToNames[1]="golden_gophers";
        typeToNames[2]="caddies";
        typeToNames[3]="legendaries";
        typeToNames[4]="members";

        // minted, burned, exchange scores, max amount
        typeToNumbers[0]=[0, 0, 1, 4700];     // GOPHER
        typeToNumbers[1]=[0, 0, 4, 150];      // GOLDEN_GOPHER
        typeToNumbers[2]=[0, 0, 2, 2350];     // CADDIE
        typeToNumbers[3]=[0, 0, 0, 18];       // LEGENDARIES
        typeToNumbers[4]=[0, 0, 0, 2500];     // MEMBER
    }

    //
    //  MINT
    //

    /// @dev mint tokens at public sale
    /// @param amount_ amount of tokens to mint
    function mintPublic(uint amount_) external payable onlyMintAllowed noContracts nonReentrant {
        require(msg.value == mintCost * amount_, "Invalid tx value!");                              //NOTE: check payment amount
        require(publicMinted + amount_ <= MAX_SUPPLY - teamReserved - mulesquadReserved, "No public mint available");                                                //NOTE: check if GOPHERS left to mint
        require(amount_ > 0 && amount_ <= maxMintPerTx, "Wrong mint amount");                      //NOTE: check if amount is correct
        require(walletToMinted[msg.sender] + amount_ <= maxPerWallet, "Wallet limit reached");      //NOTE: check max per wallet limit

        totalSupply+=amount_;
        publicMinted+=amount_;

        mintRandomInternal(amount_, msg.sender, false);
    }

    /// @dev mint tokens reserved for the team
    /// @param wallet wallet to mint tokens
    /// @param amount_ amount of tokens to mint
    function mintReserve(address wallet, uint amount_) external onlyOwner noContracts nonReentrant {
        require(reserveMinted + amount_ <= teamReserved);

        totalSupply+=amount_;
        reserveMinted+=amount_;

        mintRandomInternal(amount_,wallet, true);
    }

    /// @dev claim token with mulesquad token Id
    /// @param _mulesquadIds mulesquad token Id 
    function claimMulesquad(uint[] calldata _mulesquadIds) external onlyClaimAllowed noContracts nonReentrant {
        require(_mulesquadIds.length > 0, "Array can not be empty");
        require(mulesquadClaimed + _mulesquadIds.length <= mulesquadReserved); 
        require(walletToMinted[msg.sender] + _mulesquadIds.length <= maxPerWallet, "Wallet limit reached");

        totalSupply+=_mulesquadIds.length;
        mulesquadClaimed+=_mulesquadIds.length;

        for (uint i;i<_mulesquadIds.length;i++) {
            require(mulesquadContract.ownerOf(_mulesquadIds[i])==msg.sender, "You don't own the token");
            require(!mulesquadIdToClaimed[_mulesquadIds[i]], "Already used to claim");
            mulesquadIdToClaimed[_mulesquadIds[i]]=true;
        }

        mintRandomInternal(_mulesquadIds.length, msg.sender, false);
    }

    /// @dev exchange few tokens of type 0-2 to membership card (token types 3-4)
    /// @param _tokenIds array of tokens to be exchanged for membership
    function exchange(uint[] calldata _tokenIds) external onlyExchangeAllowed noContracts nonReentrant {
        require(_tokenIds.length>0, "Array can not be empty");
        uint scoresTotal;
        for (uint i;i<_tokenIds.length;i++) {
            require(_exists(_tokenIds[i]),"Token doesn't exists");
            require(msg.sender==ownerOf(_tokenIds[i]), "You are not the owner");
            uint scores = typeToNumbers[_tokenIds[i] / 10000][2];
            require(scores > 0, "Members can not be burned");
            scoresTotal+=scores;
        }

        require(scoresTotal == 4, "Scores total should be 4");

        totalSupply -= (_tokenIds.length-1);

        for (uint i;i<_tokenIds.length;i++) {
            burn(_tokenIds[i]);
        }

        // golden gopher burned, roll the special
        if (_tokenIds.length==1) {
            uint random = _getRandom(msg.sender, "exchange");
            // max golden gophers / golden gophers burned
            uint leftToMint = 150-typeToNumbers[1][1]+1;
            uint accumulated;

            for (uint j = 3; j<=4; j++) { 
                accumulated+=typeToNumbers[j][3]-typeToNumbers[j][0];
                if (random%leftToMint < accumulated) {
                    _mintInternal(msg.sender, j);
                    break;
                }
            }
        } else {
            _mintInternal(msg.sender, 4);
        }
    }

    /// @dev pick the random type (0-2) and mint it to specific address
    /// @param amount_ amount of tokens to be minted
    /// @param receiver wallet to get minted tokens
    function mintRandomInternal(uint amount_, address receiver, bool ignoreWalletRestriction) internal {
        if (!ignoreWalletRestriction) {
            walletToMinted[receiver]+=amount_;
        }

        uint leftToMint = MAX_SUPPLY - publicMinted - mulesquadClaimed - reserveMinted + amount_;
        uint accumulated;

        for (uint i = 0; i < amount_; i++) {
            uint random = _getRandom(msg.sender, "mint");

            accumulated = 0;
            // pick the type to mint
            for (uint j = 0; j<3; j++) { 
                accumulated+=typeToNumbers[j][3]-typeToNumbers[j][0];
                if (random%(leftToMint-i) < accumulated) {
                    _mintInternal(receiver, j);
                    break;
                }
            }
        }
    }

    /// @dev mint token of specific type to specified address
    /// @param receiver wallet to mint token to
    /// @param tokenType type of token to mint
    function _mintInternal(address receiver, uint tokenType) internal {
        uint mintId = ++typeToNumbers[tokenType][0] + tokenType*10000;
        _mint(receiver, mintId);
    }

    /// @dev burn the token specified
    /// @param _tokenId token Id to burn
    function burn(uint _tokenId) internal {
        uint tokenType=_tokenId / 10000;
        typeToNumbers[tokenType][1]++;
        _burn(_tokenId);
    }

    //
    //  VIEW
    //

    /// @dev return total amount of tokens of a type owned by wallet
    function ownedOfType(address address_, uint type_) external view noSameBlockAsAction returns(uint) {
        return addressToTypesOwned[address_][type_];
    }

    /// @dev return total amount of tokens minted
    function mintedTotal() external view returns (uint) {
        uint result;
        for (uint i=0;i<3;i++) {
            result+=typeToNumbers[i][0];
        }
        return result;
    }

    /// @dev return the array of tokens owned by wallet, never use from the contract (!)
    /// @param address_ wallet to check
    function walletOfOwner(address address_, uint type_) external view returns (uint[] memory) {
        require(callerToLastBlockAction[address_] < block.number, "Please try again on next block");
        uint[] memory _tokens = new uint[](addressToTypesOwned[address_][type_]);
        uint index;
        uint tokenId;
        uint type_minted=typeToNumbers[type_][0];
        for (uint j=1;j<=type_minted;j++) {
            tokenId=j+type_*10000;
            if (_exists(tokenId)) {
                if (ownerOf(tokenId)==address_) {_tokens[index++]=(tokenId);}
            }
        }
        return _tokens;
    }

    /// @dev return the metadata URI for specific token
    /// @param _tokenId token to get URI for
    function tokenURI(uint _tokenId) public view override noSameBlockAsAction returns (string memory) {
        require(_exists(_tokenId), "Token does not exist");
        if (!revealed) {
            return string(abi.encodePacked(_baseTokenURI, '/unrevealed/json/metadata.json'));
        }
        return string(abi.encodePacked(_baseTokenURI, '/', typeToNames[_tokenId/10000],'/','json/',Strings.toString(_tokenId%10000)));
    }

    /// @dev get the actual amount of tokens of specific type
    /// @param type_ token type (check typeToNumbers array)
    function getSupplyByType(uint type_) external view noSameBlockAsAction returns(uint) {
        return typeToNumbers[type_][0]-typeToNumbers[type_][1];
    }

    //
    // ONLY OWNER
    //

    /// @dev reveal the real links to metadata
    function reveal() external onlyOwner {
        revealed=true;
    }

    /// @dev free all Mulesquad reserved tokens for the public sale, can not be reverted
    function mulesquadClaimEnd() external onlyOwner {
        mulesquadReserved=mulesquadClaimed;
    }

    /// @dev switch mint allowed status
    function switchMintAllowed() external onlyOwner {
        mintAllowed=!mintAllowed;
    }

    /// @dev switch exchange allowed status
    function switchExchangeAllowed() external onlyOwner {
        exchangeAllowed=!exchangeAllowed;
    }

    /// @dev switch claim allowed status
    function switchClaimAllowed() external onlyOwner {
        claimAllowed=!claimAllowed;
    }

    /// @dev set wallet mint allowance
    /// @param maxPerWallet_ new wallet allowance, default is 20
    function setMaxPerWallet(uint maxPerWallet_) external onlyOwner {
        maxPerWallet=maxPerWallet_;
    }

    /// @dev Set base URI for tokenURI
    function setBaseTokenURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI=baseURI_;
    }

    function setMulesquadContract(address mulesquadAddress_) external onlyOwner {
        mulesquadContract=IMulesquad(mulesquadAddress_);
    }

    /// @dev transfer ownership
    /// @param owner_ new contract owner
    function transferOwnership(address owner_) external onlyOwner {
        owner=owner_;
    }

    /// @dev withdraw all ETH accumulated, 10% share goes to solidity dev
    function withdrawEther() external onlyOwner {
        require(address(this).balance > 0);
        uint share = address(this).balance/10;
        payable(0xdA00D453F87db473BC84221063f4a27298F7FCca).transfer(share);
        payable(owner).transfer(address(this).balance);
    }

    //
    // HELPERS
    //

    /// @dev get pseudo random uint
    function _getRandom(address _address, bytes32 _addition) internal returns (uint){
        callerToLastBlockAction[tx.origin] = block.number;
        return uint256(
            keccak256(
                abi.encodePacked(
                    _address, 
                    block.timestamp, 
                    ++NOUNCE,
                    _addition,
                    block.basefee, 
                    block.timestamp, 
                    entropySauce)));
    }

    //
    //  MODIFIERS
    //

    /// @dev allow execution when mint allowed only
    modifier onlyMintAllowed() {
        require(mintAllowed, 'Mint not allowed');
        _;
    }

    /// @dev allow execution when claim only
    modifier onlyClaimAllowed() {
        require(claimAllowed, 'Claim not allowed');
        _;
    }

    /// @dev allow execution when exchange allowed only
    modifier onlyExchangeAllowed() {
        require(exchangeAllowed, "Exchange not allowed");
        _;
    }

    /// @dev allow execution when caller is owner only
    modifier onlyOwner() {
        require(owner == msg.sender, "You are not the owner");
        _;
    }

    /// @dev do not allow execution if caller is contract
    modifier noContracts() {
        uint256 size;
        address acc = msg.sender;
        assembly { size := extcodesize(acc)}

        require(msg.sender == tx.origin,  "tx.origin != msg.sender");
        require(size == 0,                "Contract calls are not allowed");
        _;

        // We'll use the last caller hash to add entropy to next caller
        entropySauce = keccak256(abi.encodePacked(acc, block.coinbase));
    }

    /// @dev don't allow view functions in same block as action that changed the state
    modifier noSameBlockAsAction() {
        require(callerToLastBlockAction[tx.origin] < block.number, "Please try again on next block");
        _;
    }

    //
    // OVERRIDE
    //

    /// @dev override to prohibit to get results in same block as random was rolled
    function balanceOf(address owner_) public view virtual override(ERC721) returns (uint256) {
        require(callerToLastBlockAction[owner_] < block.number, "Please try again on next block");
        return super.balanceOf(owner_);
    }

    /// @dev override to prohibit to get results in same block as random was rolled
    function ownerOf(uint256 tokenId) public view virtual override(ERC721) returns (address) {
        address addr = super.ownerOf(tokenId);
        require(callerToLastBlockAction[addr] < block.number, "Please try again on next block");
        return addr;
    }

    /// @dev override to track how many of a type wallet hold, required for custom walletOfOwner and ownedOfType
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override virtual {
        uint tokenType = tokenId/10000;
        if (from!=address(0)) { addressToTypesOwned[from][tokenType]--; }
        if (to!=address(0)) { addressToTypesOwned[to][tokenType]++; }
    }
}