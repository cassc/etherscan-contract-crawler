pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ERC721Full.sol";
import "./IMintPass.sol";
import "./ValidateString.sol";
import "./VerifySignature.sol";

contract BlockBots is
    Ownable,
    ReentrancyGuard,
    AccessControl,
    ERC721Full,
    ValidateString,
    VerifySignature
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant MINT_PASS_CONTRACT_ROLE =
        keccak256("MINT_PASS_CONTRACT_ROLE");
    bytes32 public constant BUNDLE_CONTRACT_ROLE =
        keccak256("BUNDLE_CONTRACT_ROLE");
    uint256 private BLOCK_BOTS_TOTAL_SUPPLY = 9998;
    uint256 public MAX_BLOCK_BOTS_CLAIMED_BY_RAFFLE = 2000;
    uint256 public constant MAX_MINT_LIMIT = 50;
    uint256 public totalBlockBotsMinted;
    uint256 public totalClaimedBlockBotsByRaffle;
    address public redeemerAddress;
    uint256 public nameChangePrice;
    address public immutable MINT_PASS_ADDRESS;
    address public immutable INDORSE_TOKEN_ADDRESS;
    address public changeNameProtocolFeeAddress;
    bool public pauseDeflatinate = true;
    uint256 private _currentTokenId = 0;
    uint256 private _deflatinatedTokenId = 10000;
    string private _uri;

    struct TokenLineageDetail {
        uint256 gen;
        uint256 parent1;
        uint256 parent2;
    }
    /**
     * @dev maps tokenId with tokenName.
     */
    mapping(uint256 => string) public tokenNameByTokenId;
    mapping(uint256 => TokenLineageDetail) private _lineage;

    event Mint(address indexed _recipient, uint256 _startId, uint256 _quantity);
    event Pause(bool _pauseDeflatinate);
    event Deflatination(
        uint256 indexed _tokenId1,
        uint256 indexed _tokenId2,
        uint256 _newToken
    );

    /**
     * @dev Initializes the contract by setting a `MINT_PASS_ADDRESS`, `changeNameProtocolFeeAddress`, `indorsetokenAddress`, `mintPassReserveTokens`
     *       and `tokenDetailchangePrice`  to the tokens.
     * @param _mintPassAddress is an address
     * @param _changeNameProtocolFeeAddress is an address
     * @param _indorseTokenAddress is an address
     * @param _nameChangePrice is uint256
     * @param _baseUri is string
     */
    constructor(
        address _mintPassAddress,
        address _changeNameProtocolFeeAddress,
        address _indorseTokenAddress,
        address _redeemerAddress,
        address _bundleAddress,
        uint256 _nameChangePrice,
        string memory _baseUri
    ) ERC721Full("BlockBots", "BB") {
        require(
            _mintPassAddress != address(0),
            "_mintPassAddress cannot be zero"
        );
        require(
            _changeNameProtocolFeeAddress != address(0),
            "_changeNameProtocolFeeAddress cannot be zero"
        );
        require(
            _indorseTokenAddress != address(0),
            "_indorseTokenAddress cannot be zero"
        );
        require(
            _redeemerAddress != address(0),
            "_redeemerAddress cannot be zero"
        );
        nameChangePrice = _changeToWei(_nameChangePrice);
        changeNameProtocolFeeAddress = _changeNameProtocolFeeAddress;
        MINT_PASS_ADDRESS = _mintPassAddress;
        _uri = _baseUri;
        INDORSE_TOKEN_ADDRESS = _indorseTokenAddress;
        redeemerAddress = _redeemerAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(MINT_PASS_CONTRACT_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(MINT_PASS_CONTRACT_ROLE, _mintPassAddress);
        _setRoleAdmin(BUNDLE_CONTRACT_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(BUNDLE_CONTRACT_ROLE, _bundleAddress);
    }

    /**
     * @notice Query if a contract implements an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     *  uses less than 30,000 gas.
     * @return `true` if the contract implements `interfaceId` and
     *  `interfaceId` is not 0xffffffff, `false` otherwise
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC721Full)
        returns (bool)
    {
        return
            AccessControl.supportsInterface(interfaceId) ||
            ERC721Full.supportsInterface(interfaceId);
    }

    function remainingBlockBots() public view returns (uint256) {
        return
            getMaxTotalSupply().sub(totalBlockBotsMinted).sub(
                IMintPass(MINT_PASS_ADDRESS).totalSupply(1) // 1 is pass because mintId is 1
            );
    }

    // Remaining Blockbots is substracted with total unclaimed BlockBots
    function remainingBlockBotsByBundles() public view returns (uint256) {
        return
            remainingBlockBots().add(totalClaimedBlockBotsByRaffle).sub(
                MAX_BLOCK_BOTS_CLAIMED_BY_RAFFLE
            );
    }

    function getMaxTotalSupply() public view virtual returns (uint256) {
        return BLOCK_BOTS_TOTAL_SUPPLY;
    }

    function getNextDeflatinatedTokenId() public view returns (uint256) {
        return _deflatinatedTokenId.add(1);
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function getNextTokenId() public view returns (uint256) {
        return _currentTokenId.add(1);
    }

    function calculateGen(uint256 tokenId1, uint256 tokenId2)
        public
        view
        returns (uint256)
    {
        uint256 genToken1 = _getGenOfToken(tokenId1);
        uint256 genToken2 = _getGenOfToken(tokenId2);
        if (genToken1 > genToken2) return genToken1.add(1);
        return genToken2.add(1);
    }

    function getParentOfBots(uint256 tokenId)
        external
        view
        returns (TokenLineageDetail memory)
    {
        TokenLineageDetail memory data = _lineage[tokenId];
        if (tokenId < getMaxTotalSupply().add(1)) {
            data.gen = 1;
        }
        return data;
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i = i.add(1)) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function isTokenActive(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev Set the sale and redeem pause by owner.
     * @param _pauseDeflatinate is a bool value.
     */
    function setPause(bool _pauseDeflatinate) external onlyOwner {
        pauseDeflatinate = _pauseDeflatinate;
        emit Pause(_pauseDeflatinate);
    }

    /**
     * @dev Set the sale and redeem pause by owner.
     * @param _changeNameProtocolFeeAddress is an address where we send fee for changeName.
     */
    function setChangeNameProtocolFeeAddress(
        address _changeNameProtocolFeeAddress
    ) external onlyOwner {
        require(
            changeNameProtocolFeeAddress != address(0),
            "cannot set to zero address"
        );
        changeNameProtocolFeeAddress = _changeNameProtocolFeeAddress;
    }

    function getRaffleMessage(
        address _recipient,
        uint256 _quantity,
        uint256 _blockHeight
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_recipient, _quantity, _blockHeight));
    }

    function setRedeemerAddress(address _redeemer) external onlyOwner {
        require(_redeemer != address(0), "address cannot set to zero");
        redeemerAddress = _redeemer;
    }

    function claimBlockBotsByRaffle(
        uint256 _quantity,
        uint256 _blockHeight,
        bytes memory _redeemerSignatureHash
    ) external nonReentrant {
        require(_quantity != 0, "quantity cannot be zero");
        require(
            totalClaimedBlockBotsByRaffle.add(_quantity) <=
                MAX_BLOCK_BOTS_CLAIMED_BY_RAFFLE
        );
        totalClaimedBlockBotsByRaffle = totalClaimedBlockBotsByRaffle.add(
            _quantity
        );
        _setMessageHashClaimed(
            getRaffleMessage(msg.sender, _quantity, _blockHeight),
            redeemerAddress,
            _redeemerSignatureHash
        );
        _mintBatch(msg.sender, _quantity);
    }

    /**
     * @dev set the price of a token detail change by owner.
     * @param _nameChangePrice is a integer value.
     */
    function setNameChangePrice(uint256 _nameChangePrice) external onlyOwner {
        require(_nameChangePrice != 0, "cannot set price zero");
        nameChangePrice = _changeToWei(_nameChangePrice);
    }

    /**
     * @dev deflatinate the token ID.
     * @param tokenId1, is a integer value denotes the token ID.
     * @param tokenId2, is a integer value denotes the token ID.
     */
    function deflatinate(uint256 tokenId1, uint256 tokenId2)
        external
        nonReentrant
    {
        require(!pauseDeflatinate, "deflatination of tokens are paused");
        uint256 deflatinatedTokenId = getNextDeflatinatedTokenId();
        TokenLineageDetail storage data = _lineage[deflatinatedTokenId];
        data.parent1 = tokenId1;
        data.parent2 = tokenId2;
        data.gen = calculateGen(tokenId1, tokenId2);
        _incrementDefaltinatedTokenId();
        _burnBot(tokenId1);
        _burnBot(tokenId2);
        _safeMint(msg.sender, deflatinatedTokenId);
        emit Deflatination(tokenId1, tokenId2, deflatinatedTokenId);
    }

    function _burnBot(uint256 tokenId) internal {
        require(ownerOf(tokenId) == msg.sender, "sender is not owner of token");
        _burn(tokenId);
    }

    function mintBlockBotsByBundle(address _recipient, uint256 _quantity)
        external
        onlyRole(BUNDLE_CONTRACT_ROLE)
        nonReentrant
    {
        _mintBatch(_recipient, _quantity);
    }

    function redeemMintPass(address _recipient, uint256 _quantity)
        external
        onlyRole(MINT_PASS_CONTRACT_ROLE)
        nonReentrant
    {
        _mintBatch(_recipient, _quantity);
    }

    function endRaffle() external onlyOwner {
        MAX_BLOCK_BOTS_CLAIMED_BY_RAFFLE = totalClaimedBlockBotsByRaffle;
    }

    function mintUnsoldBlockBots() external onlyOwner {
        uint256 BBUnsold = remainingBlockBots();
        if (BBUnsold > MAX_MINT_LIMIT) {
            _mintBatch(msg.sender, MAX_MINT_LIMIT);
        } else {
            _mintBatch(msg.sender, BBUnsold);
        }
    }

    /**
     * @dev Changes the name for Hashmask tokenId
     */
    function changeName(uint256 tokenId, string memory newName)
        external
        nonReentrant
    {
        require(
            msg.sender == ownerOf(tokenId),
            "ERC721: caller is not the owner"
        );
        require(validateName(newName) == true, "Not a valid new name");
        require(
            sha256(bytes(newName)) !=
                sha256(bytes(tokenNameByTokenId[tokenId])),
            "New name is same as the current one"
        );
        require(isNameReserved(newName) == false, "Name already reserved");
        // If already named, dereserve old name
        if (bytes(tokenNameByTokenId[tokenId]).length > 0) {
            _toggleReserveName(tokenNameByTokenId[tokenId], false);
        }
        _toggleReserveName(newName, true);
        tokenNameByTokenId[tokenId] = newName;
        uint256 burnAmount = (nameChangePrice.mul(30)).div(100);
        _sendERC20(msg.sender, address(0), burnAmount); // 30% tokens as protocol fee
        _sendERC20(
            msg.sender,
            changeNameProtocolFeeAddress,
            nameChangePrice.sub(burnAmount)
        ); // 100% tokens as protocol fee
        emit NameChange(tokenId, newName);
    }

    function withdraw() external payable onlyOwner nonReentrant {
        _sendEther(owner(), address(this).balance);
    }

    function _mintBatch(address _recipient, uint256 _quantity) internal {
        require(_quantity <= MAX_MINT_LIMIT, "Exceeds maximum mint limit");
        require(_quantity <= remainingBlockBots(), "Exceeds available bots");
        totalBlockBotsMinted = totalBlockBotsMinted.add(_quantity);
        uint256 tokenId;
        uint256 startTokenId = getNextTokenId();
        for (uint256 i = 0; i < _quantity; i = i.add(1)) {
            tokenId = getNextTokenId();
            _incrementTokenId();
            _safeMint(_recipient, tokenId);
        }
        emit Mint(_recipient, startTokenId, _quantity);
    }

    function _sendEther(address _recipient, uint256 _quantity) internal {
        (bool success, ) = payable(_recipient).call{value: _quantity}("");
        require(success, "Withdraw failure");
    }

    function _sendERC20(
        address _from,
        address _to,
        uint256 _quantity
    ) internal {
        require(
            IERC20(INDORSE_TOKEN_ADDRESS).transferFrom(_from, _to, _quantity),
            "Unable to transfer Indorse tokens"
        );
    }

    /**
     * @dev increments the value of _currentTokenId
     */
    function _incrementTokenId() internal {
        _currentTokenId = _currentTokenId.add(1);
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function _incrementDefaltinatedTokenId() internal {
        _deflatinatedTokenId = _deflatinatedTokenId.add(1);
    }

    function _getGenOfToken(uint256 tokenId) internal view returns (uint256) {
        require(
            isTokenActive(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        TokenLineageDetail memory data = _lineage[tokenId];
        if (data.gen == 0) return 1;
        return data.gen;
    }

    function _changeToWei(uint256 _value) internal pure returns (uint256) {
        return _value.mul(1 wei);
    }
}