// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./DefaultOperatorFilterer.sol";
import "./IChadinu.sol";

contract SugarHeadNFT is ERC721, ERC721URIStorage, Ownable, Pausable, DefaultOperatorFilterer, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public constant TOTAL_SUPPLY = 1750;
    uint256 private price;
    Phase public currentPhase;
    IChadInuVIPClub public ChadinuVip;
    IERC721 public DVDA;
    string public baseTokenURI;
    uint256 private _numAvailableTokens;

    mapping(address => uint256[]) private tokenIdsOf;
    mapping(address => uint32) public freeMinters;
    mapping(address => bool) public isEarlyMinter;
    mapping(uint => uint) private _availableTokens;

    enum Phase {
        FREE_MINT,
        EARLY_MINT,
        PUBLIC_MINT
    }

    modifier onlyOneFree() {
        require(this.balanceOf(msg.sender) == 0, "Only one NFT is free");
        _;
    }

    modifier onlyValidAmount(uint32 _amount) {
        require(_amount <= 10 && _amount > 0, "Invalid amount");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address chadinu,
        address dvda,
        uint256 nftPrice,
        uint256 maxSupply
    ) ERC721(name, symbol) {
        price = nftPrice;
        ChadinuVip = IChadInuVIPClub(chadinu);
        DVDA = IERC721(dvda);
        _numAvailableTokens = maxSupply;
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function addTokenIdTo(address _to, uint256 _tokenId) internal {
        tokenIdsOf[_to].push(_tokenId);
    }

    function removeTokenIdFrom(address _from, uint256 _tokenId) internal {
        uint256 tokenIndex;
        uint256[] memory _tokenIdsOf = tokenIdsOf[_from];
        for (uint32 i = 0; i < _tokenIdsOf.length; i++) {
            if (_tokenIdsOf[i] == _tokenId) {
                tokenIndex = i;
                break;
            }
        }
        uint256 lastTokenIndex = _tokenIdsOf.length - 1;
        uint256 lastToken = _tokenIdsOf[lastTokenIndex];

        tokenIdsOf[_from][tokenIndex] = lastToken;
        tokenIdsOf[_from][lastTokenIndex] = 0;

        tokenIdsOf[_from].pop();
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override onlyAllowedOperator(_from) {
        require(_from != address(0));
        require(_to != address(0));
        super.transferFrom(_from, _to, _tokenId);
        removeTokenIdFrom(_from, _tokenId);
        addTokenIdTo(_to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override onlyAllowedOperator(_from) {
        // solium-disable-next-line arg-overflow
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public override onlyAllowedOperator(_from) {
        super.safeTransferFrom(_from, _to, _tokenId, _data);
        removeTokenIdFrom(_from, _tokenId);
        addTokenIdTo(_to, _tokenId);
    }

    receive() external payable {}

    function _mint(address to) internal {
        addTokenIdTo(msg.sender, _tokenIds.current());
        _tokenIds.increment();
        _safeMint(to, _tokenIds.current());
    }

    function _mintRandom(address to, uint _numToMint) internal virtual {
        require(_msgSender() == tx.origin, "Contracts cannot mint");
        require(to != address(0), "ERC721: mint to the zero address");
        require(_numToMint > 0, "ERC721r: need to mint at least one token");
        
        // TODO: Probably don't need this as it will underflow and revert automatically in this case
        require(_numAvailableTokens >= _numToMint, "ERC721r: minting more tokens than available");
        
        uint updatedNumAvailableTokens = _numAvailableTokens;
        for (uint256 i; i < _numToMint; ++i) { // Do this ++ unchecked?
            uint256 tokenId = getRandomAvailableTokenId(to, updatedNumAvailableTokens);
            
            _mintIdWithoutBalanceUpdate(to, tokenId);

            addTokenIdTo(msg.sender, tokenId);
            _tokenIds.increment();
            
            --updatedNumAvailableTokens;
        }
        
        _numAvailableTokens = updatedNumAvailableTokens;
    }

    function _mintIdWithoutBalanceUpdate(address to, uint256 tokenId) private {
        _safeMint(to, tokenId);
    }

    function buyNFTWithChadinu() external onlyOneFree nonReentrant {
        require(currentPhase == Phase.FREE_MINT, "No Free Sale");
        require(_tokenIds.current() + 1 <= TOTAL_SUPPLY, "No Enoguh NFTs");
        require(ChadinuVip.balanceOf(msg.sender) > 0, "No Chadinu VIP");

        _mintRandom(msg.sender, 1);
    }

    function buyNFTForFree() external nonReentrant {
        require(currentPhase == Phase.FREE_MINT, "No Free Sale");
        require(
            _tokenIds.current() + freeMinters[msg.sender] <= TOTAL_SUPPLY,
            "No Enoguh NFTs"
        );
        require(freeMinters[msg.sender] > 0, "Not Whitelisted");
        require(
            this.balanceOf(msg.sender) <=
                (ChadinuVip.balanceOf(msg.sender) > 0 ? 1 : 0),
            "Already minted free NFTs"
        );

        _mintRandom(msg.sender, freeMinters[msg.sender]);
    }

    function buyNFTEarly (uint32 _amount)
        external
        payable
        onlyValidAmount(_amount)
        nonReentrant
    {
        require(currentPhase == Phase.EARLY_MINT, "No Early Sale");
        require(_amount * price == msg.value, "Insufficent Fund");
        require(
            _tokenIds.current() + _amount <= TOTAL_SUPPLY,
            "No Enoguh NFTs"
        );
        require(
            DVDA.balanceOf(msg.sender) > 0 || isEarlyMinter[msg.sender],
            "Not Whitelisted"
        );

        _mintRandom(msg.sender, _amount);
    }

    function buyNFTsInPublic(uint32 _amount)
        external
        payable
        onlyValidAmount(_amount)
        nonReentrant
    {
        require(currentPhase == Phase.PUBLIC_MINT, "No Public Sale");
        require(_amount * price == msg.value, "Insufficent Fund");
        require(
            _tokenIds.current() + _amount <= TOTAL_SUPPLY,
            "No Enoguh NFTs"
        );
        _mintRandom(msg.sender, _amount);
    }

    function getAvailableTokenAtIndex(uint256 indexToUse, uint updatedNumAvailableTokens)
        internal
        returns (uint256)
    {
        uint256 valAtIndex = _availableTokens[indexToUse];
        uint256 result;
        if (valAtIndex == 0) {
            // This means the index itself is still an available token
            result = indexToUse;
        } else {
            // This means the index itself is not an available token, but the val at that index is.
            result = valAtIndex;
        }

        uint256 lastIndex = updatedNumAvailableTokens - 1;
        uint256 lastValInArray = _availableTokens[lastIndex];
        if (indexToUse != lastIndex) {
            // Replace the value at indexToUse, now that it's been used.
            // Replace it with the data from the last index in the array, since we are going to decrease the array size afterwards.
            if (lastValInArray == 0) {
                // This means the index itself is still an available token
                _availableTokens[indexToUse] = lastIndex;
            } else {
                // This means the index itself is not an available token, but the val at that index is.
                _availableTokens[indexToUse] = lastValInArray;
            }
        }
        if (lastValInArray != 0) {
            // Gas refund courtsey of @dievardump
            delete _availableTokens[lastIndex];
        }
        
        return result;
    }

    function getRandomAvailableTokenId(address to, uint updatedNumAvailableTokens)
        internal
        returns (uint256)
    {
        uint256 randomNum = uint256(
            keccak256(
                abi.encode(
                    to,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1),
                    address(this),
                    updatedNumAvailableTokens
                )
            )
        );
        uint256 randomIndex = randomNum % updatedNumAvailableTokens;
        return getAvailableTokenAtIndex(randomIndex, updatedNumAvailableTokens);
    }

    function getTokenIdsOf(address owner)
        external
        view
        returns (uint256[] memory)
    {
        return tokenIdsOf[owner];
    }

    function getTotalSupply() external pure returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function getCurrentTokenId() external view returns (uint256) {
        return _tokenIds.current();
    }

    function getPrice() external view returns (uint256) {
        return price;
    }
    
    function addFreeMinters(
        address[] calldata _minters,
        uint32[] calldata _amounts
    ) external onlyOwner {
        require(_minters.length == _amounts.length, "Invalid Inputs");
        for (uint256 i = 0; i < _minters.length; i++) {
            freeMinters[_minters[i]] = _amounts[i];
        }
    }

    function addEarlyMinters(address[] calldata _minters, bool _flag)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _minters.length; i++) {
            isEarlyMinter[_minters[i]] = _flag;
        }
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setPhase(uint32 _phase) external onlyOwner {
        if (_phase == 0) currentPhase = Phase.FREE_MINT;
        else if (_phase == 1) currentPhase = Phase.EARLY_MINT;
        else if (_phase == 2) currentPhase = Phase.PUBLIC_MINT;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId)));
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        receiver = owner();
        royaltyAmount = _salePrice / 10;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}