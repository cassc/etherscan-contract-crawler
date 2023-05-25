// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ITimeCatsLoveEmHateEm.sol";
import "./ISlicesOfTIMEArtists.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SlicesOfTIMECovers is ERC721 {
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract"); // solium-disable-line security/no-tx-origin

        _;
    }

    modifier contractIsNotFrozen() {
        require(_frozen == false, "This function cannot be called anymore");

        _;
    }

    struct TokenData {
        uint256 totalTokens;
        uint256 nextToken;
    }

    TokenData private tokenData;

    bool public _mintPause = true; // Reflects whether the contract mint function is paused
    bool public _burnPause = true; // Reflects whether the contract burn function is paused
    bool private _revealed = false;
    bool private _frozen;
    uint256 public mintPrice = 0.05 ether;
    string private baseURI = "ipfs://super-secret-base-uri/";
    string private blankTokenURI = "ipfs://QmXivAe3VMVFztEgy6cbbiQt9aGrr38uXdzc3QwSc7kNgK/";
    address public signerAddress = 0x7141bee235D5aaA31a0f28266bE6669901D2C1f6;
    address public rewardContract = 0x000000000000000000000000000000000000dEaD;
    address public mintPassAddress = 0x7581F8E289F00591818f6c467939da7F9ab5A777;

    mapping(address => uint256) public mintedTokensPerWallet;
    mapping(address => bool) public hasUsedAPass;

    constructor() ERC721("SlicesOfTIMECovers", "SOTC") {
        tokenData.totalTokens = 17325;
    }

    // ONLY OWNER FUNCTIONS

    /**
     * @dev Sets the mint price
     */
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /**
     * @dev Sets the total token supply
     */
    function setTotalTokens(uint256 _totalTokens) external onlyOwner contractIsNotFrozen {
        tokenData.totalTokens = _totalTokens;
    }

    /**
     * @dev Sets the blank token URI
     */
    function setBlankTokenURI(string memory _uri) external onlyOwner contractIsNotFrozen {
        blankTokenURI = _uri;
    }

    /**
     * @dev Sets the base URI
     */
    function setBaseURI(string memory _uri) external onlyOwner contractIsNotFrozen {
        baseURI = _uri;
    }

    /**
     * @dev Sets the signer address
     */
    function setSignerAddress(address _signerAddress) external onlyOwner contractIsNotFrozen {
        signerAddress = _signerAddress;
    }

    /**
     * @dev Sets the address of the TIME mint pass smart contract
     */
    function setMintPassAddress(address _mintPassAddress) external onlyOwner contractIsNotFrozen {
        mintPassAddress = _mintPassAddress;
    }

    /**
      * @dev Sets the address of the Reward contract
     */
    function setRewardContract(address _address) external onlyOwner contractIsNotFrozen {
        rewardContract = _address;
    }

    /**
     * @dev Sets the pause status for the mint period
     */
    function pauseMint(bool val) public onlyOwner contractIsNotFrozen {
        _mintPause = val;
    }

    /**
     * @dev Sets the pause status for the burn period
     */
    function pauseBurn(bool val) public onlyOwner contractIsNotFrozen {
        _burnPause = val;
    }

    /**
     * @dev Give random tokens to the provided address
     */
    function devMintTokensToAddress(address _address, uint256 amount) external onlyOwner contractIsNotFrozen {
        uint256 nextToken = tokenData.nextToken;
        require(tokenData.totalTokens - nextToken >= amount, "No tokens left to be minted");

        uint256[] memory tokenIds = new uint256[](amount);

        for (uint256 i; i < amount; i++) {
            tokenIds[i] = nextToken;
            nextToken++;
        }

        _batchMint(_address, tokenIds);

        tokenData.nextToken += amount;
    }

    /**
     * @dev Give random tokens to the provided addresses
     */
    function devMintTokensToAddresses(address[] memory _addresses) external onlyOwner contractIsNotFrozen {
        uint256 nextToken = tokenData.nextToken;
        require(tokenData.totalTokens - nextToken >= _addresses.length, "No tokens left to be minted");

        for (uint256 i; i < _addresses.length; i++) {
            _safeMint(_addresses[i], uint256(nextToken));
            nextToken++;
        }

        tokenData.nextToken += _addresses.length;

    }

    /**
     * @dev Sets the isRevealed variable to true
     */
    function revealDrop(string memory _uri) external onlyOwner contractIsNotFrozen {
        baseURI = _uri;
        _revealed = true;
    }

    /**
     * @dev Allows for withdraw of Ether from the contract
     */
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev Sets the isFrozen variable to true
     */
    function freezeContract() external onlyOwner {
        _frozen = true;
    }

    // Begin Public Functions

    /**
     * @dev Mint a Slice of TIME
     */
    function mint(uint256 amount, uint256 _maxMint, bool _hasPass, bytes calldata _signature)
    external payable callerIsUser contractIsNotFrozen {
        require(!_mintPause, "Mint has not started or is paused right now");

        uint256 nextToken = tokenData.nextToken;
        require(tokenData.totalTokens - nextToken >= amount, "No tokens left to be minted");

        require(mintedTokensPerWallet[msg.sender] + amount <= _maxMint, "Caller cannot mint more tokens");

        uint256 totalMintPrice = mintPrice * amount;
        require(msg.value >= totalMintPrice, "Not enough Ether to mint the token");

        bytes32 messageHash = generateMessageHash(msg.sender, _maxMint, _hasPass);
        address recoveredWallet = ECDSA.recover(messageHash, _signature);
        require(recoveredWallet == signerAddress, "Invalid signature for the caller");

        uint256[] memory tokenIds = new uint256[](amount);

        for (uint256 i; i < amount; i++) {
            tokenIds[i] = nextToken;
            nextToken++;
        }

        _batchMint(msg.sender, tokenIds);

        mintedTokensPerWallet[msg.sender] += amount;
        tokenData.nextToken += amount;
    }

    /**
     * @dev Mint a single Slice of TIME with a Mint Pass
     */
    function mintWithPass(uint256 _passId, uint256 _maxMint, bool _hasPass, bytes calldata _signature)
    external payable callerIsUser contractIsNotFrozen {
        require(!_mintPause, "Mint has not started or is paused right now");

        uint256 nextToken = tokenData.nextToken;
        require(tokenData.totalTokens - nextToken >= 1, "No tokens left to be minted");

        require(!hasUsedAPass[msg.sender], "Caller cannot mint any more with a mint pass");

        require(msg.value >= mintPrice, "Not enough Ether to mint the token");

        bytes32 messageHash = generateMessageHash(msg.sender, _maxMint, _hasPass);
        address recoveredWallet = ECDSA.recover(messageHash, _signature);
        require(recoveredWallet == signerAddress, "Invalid signature for the caller");

        // initialize the mint pass contract interface
        ITimeCatsLoveEmHateEm mintPassContract = ITimeCatsLoveEmHateEm(
            mintPassAddress
        );

        // Check if the mint pass is already used or not
        require(!mintPassContract.isUsed(_passId), "Pass is already used");

        // Check if the caller is the owner of the mint pass
        require(msg.sender == mintPassContract.ownerOf(_passId), "You dont own this mint pass");

        // Mint the token
        _mint(msg.sender, nextToken);

        // Set pass as used
        mintPassContract.setAsUsed(_passId);

        // Set the sender's pass used status to true
        hasUsedAPass[msg.sender] = true;

        // Increment the next token counter
        tokenData.nextToken += 1;
    }

    /**
     * @dev Warning! This function will burn the tokenId provided.
     */
    function burnForReward(uint256 tokenId) external callerIsUser contractIsNotFrozen {
        require(!_burnPause, "Burn period has not started or is paused right now");
        require(_isApprovedOrOwner(msg.sender, tokenId), "You dont have the right to burn this token");
        ISlicesOfTIMEArtists rewardTokenContract = ISlicesOfTIMEArtists(rewardContract);
        // Burn the specified tokenId
        _burn(tokenId);
        rewardTokenContract.contractMint(msg.sender);
        tokenData.totalTokens -= 1;
    }

    /**
     * @dev Returns the available number of tokens
     */
    function getAvailableTokens() public view returns (uint256) {
        return tokenData.totalTokens - tokenData.nextToken;
    }

    /**
     * @dev Returns the available number of tokens
     */
    function getCurrentSupply() public view returns (uint256) {
        return tokenData.nextToken;
    }

    /**
     * @dev Get the number of tokes minted
     */
    function getTotalMinted(address _owner) public view returns(uint256) {
        uint256 totalMinted = mintedTokensPerWallet[_owner];
        return totalMinted;
    }

    /**
     * @dev Checks if pass is already used to mint a token
     */
    function isPassUsed(address _owner) public view returns(bool) {
        return hasUsedAPass[_owner];
    }

    /**
     * @dev returns total supply of tokens
     */
    function totalSupply() public view returns(uint256) {
        return uint256(tokenData.totalTokens);
    }

    // PRIVATE / INTERNAL FUNCTIONS
    /**
     * @dev See {ERC721}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        if (!_revealed) {
            return blankTokenURI;
        }

        return baseURI;
    }

    /**
     * @dev Generate a message hash for the given parameters
     */
    function generateMessageHash(address _address, uint256 _maxMint, bool _hasPass) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n53",
                _address,
                _maxMint,
                _hasPass
            )
        );
    }
}