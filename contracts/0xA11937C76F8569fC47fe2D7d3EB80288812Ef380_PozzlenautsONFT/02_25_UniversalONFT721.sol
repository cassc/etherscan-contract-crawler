// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../ONFT721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract IERC20Extented is IERC20 {
    function decimals() public view virtual returns (uint8);
}

/// @title Interface of the UniversalONFT standard
contract UniversalONFT721 is Ownable, ONFT721, ReentrancyGuard {
    uint256 public nextMintId;
    uint256 public maxMintId;

    uint256 public publicPrice = 199;
    uint256 public greenPrice = 150;
    uint256 public initPoz = 60;

    uint256 public publicDate = block.timestamp;

    string public currentURI;

    bool public isPaused = false;

    mapping(address => uint256) public countMinted;
    mapping(address => bool) public isGLClaimed;
    mapping(address => bool) public isFLClaimed;
    mapping(uint256 => uint256) public tokenBalance;
    mapping(uint256 => uint256) public withdrawTimes;
    mapping(uint256 => string) public tokenURIs;

    bytes32 public glMerkleRoot;
    bytes32 public flMerkleRoot;

    IERC20Extented private usdcToken;

    address public treasuryWallet;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _currentURI,
        address _layerZeroEndpoint,
        uint256 _startMintId,
        uint256 _endMintId,
        address _usdcAddress,
        address _treasuryAddress
    ) ONFT721(_name, _symbol, _layerZeroEndpoint) {
        nextMintId = _startMintId;
        maxMintId = _endMintId;
        treasuryWallet = _treasuryAddress;

        setCurrentURI(_currentURI);
        setUSDCToken(_usdcAddress);
    }

    modifier isGLMerkleProoved(bytes32[] calldata _merkleProof) {
        require(
            MerkleProof.verify(
                _merkleProof,
                glMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "UniversalONFT721: Address is NOT Greenlisted yet!"
        );
        _;
    }

    modifier isFLMerkleProoved(bytes32[] calldata _merkleProof) {
        require(
            MerkleProof.verify(
                _merkleProof,
                flMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "UniversalONFT721: Address is NOT Freelisted yet!"
        );
        _;
    }

    modifier glNotClaimed() {
        require(
            isGLClaimed[msg.sender] == false,
            "UniversalONFT721: Greenlist already claimed!"
        );
        _;
    }

    modifier flNotClaimed() {
        require(
            isFLClaimed[msg.sender] == false,
            "UniversalONFT721: Freenlist already claimed!"
        );
        _;
    }

    modifier isPublicOpen() {
        require(
            block.timestamp >= publicDate,
            "UniversalONFT721: Public mint is not opened yet!"
        );
        _;
    }

    modifier isSpecialOpen() {
        require(
            block.timestamp >= publicDate - 1 days,
            "UniversalONFT721: Special mint is not opened yet!"
        );
        _;
    }

    function _mint(uint256 _mintCount, uint256 _mintPrice) private {
        require(
            nextMintId + _mintCount - 1 <= maxMintId,
            "UniversalONFT721: max mint limit reached"
        );
        require(isPaused == false, "UniversalONFT721: Mint is Paused");

        if (_mintPrice > 0)
            usdcToken.transferFrom(
                msg.sender,
                treasuryWallet,
                _mintCount * _mintPrice * 10**usdcToken.decimals()
            );

        for (uint256 i = 0; i < _mintCount; i++) {
            tokenBalance[nextMintId] = initPoz;
            uint256 newId = nextMintId;
            _safeMint(msg.sender, newId);
            _setTokenURI(newId, string(abi.encodePacked(currentURI, Strings.toString(newId))));
            nextMintId++;
        }

        if(nextMintId == maxMintId + 1) {
            _setPaused(true);
        }
    }

    function publicMint(uint256 _mintCount) external payable isPublicOpen returns(uint256) {
        require(
            countMinted[msg.sender] + _mintCount <= 3,
            "UniversalONFT721: Mint count limited"
        );

        _mint(_mintCount, publicPrice);
        _setCountMinted(msg.sender, countMinted[msg.sender] + _mintCount);

        return nextMintId - 1;
    }

    function greenListMint(bytes32[] calldata _merkleProof)
        external
        payable
        isSpecialOpen
        isGLMerkleProoved(_merkleProof)
        glNotClaimed
        returns (uint256)
    {
        _mint(1, greenPrice);
        _setGLClaimed(msg.sender, true);

        return nextMintId - 1;
    }

    function freeListMint(bytes32[] calldata _merkleProof)
        external
        payable
        isSpecialOpen
        isFLMerkleProoved(_merkleProof)
        flNotClaimed
        returns (uint256)
    {
        _mint(1, 0);
        _setFLClaimed(msg.sender, true);

        return nextMintId - 1;
    }

    function isFListed(bytes32[] calldata _merkleProof) external view returns(bool) {
        return MerkleProof.verify(_merkleProof, flMerkleRoot, keccak256(abi.encodePacked(msg.sender)));
    }
    
    function isGListed(bytes32[] calldata _merkleProof) external view returns(bool) {
        return MerkleProof.verify(_merkleProof, glMerkleRoot, keccak256(abi.encodePacked(msg.sender)));
    }

    function setGLMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        glMerkleRoot = _merkleRoot;
    }

    function setFLMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        flMerkleRoot = _merkleRoot;
    }

    function setCountMinted(address _sender, uint256 _count) public onlyOwner {
        _setCountMinted(_sender, _count);
    }

    function _setCountMinted(address _sender, uint256 _count) internal {
        countMinted[_sender] = _count;
    }

    function setGLClaimed(address _sender, bool _isClamed) external onlyOwner {
        _setGLClaimed(_sender, _isClamed);
    }

    function _setGLClaimed(address _sender, bool _isClamed) internal {
        isGLClaimed[_sender] = _isClamed;
    }

    function setFLClaimed(address _sender, bool _isClamed) public onlyOwner {
        _setFLClaimed(_sender, _isClamed);
    }

    function _setFLClaimed(address _sender, bool _isClamed) internal {
        isFLClaimed[_sender] = _isClamed;
    }

    function setPaused(bool _isPaused) external onlyOwner {
        _setPaused(_isPaused);
    }

    function _setPaused(bool _isPaused) internal {
        isPaused = _isPaused;
    }

    function setMintPrice(uint256 _publicPrice, uint256 _greenPrice)
        public
        onlyOwner
    {
        publicPrice = _publicPrice;
        greenPrice = _greenPrice;
    }

    function setCurrentURI(string memory _currentURI) public onlyOwner {
        currentURI = _currentURI;
    }

    function setSpecialPack(uint256 _startMintId, uint _maxMintId, string memory _newURI) public onlyOwner {
        nextMintId = _startMintId;
        maxMintId = _maxMintId;
        currentURI = _newURI;
        
        _setPaused(false);
    }

    function setUSDCToken(address _newAddress) public onlyOwner {
        usdcToken = IERC20Extented(_newAddress);
    }

    function setPublicDate(uint256 _publicDate) public onlyOwner {
        publicDate = _publicDate;
    }

    function setTreasuryWallet(address treasure) external onlyOwner {
        treasuryWallet = treasure;
    }

}