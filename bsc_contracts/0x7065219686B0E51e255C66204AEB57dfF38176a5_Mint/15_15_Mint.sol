// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

interface IMint {
    function getNFTRarity(uint256 tokenID) external view returns (uint8);

    function retrieveStolenNFTs() external returns (bool, uint256[] memory);
}

interface IStaking {
    function startFarming(uint256 _startDate) external;
}

contract Mint is ERC165, IERC721, IERC721Metadata, Ownable {
    using Address for address;
    using Strings for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Mapping that stores all token ids of an owner (owner => tokenIds[])
    mapping(address => EnumerableSet.UintSet) internal ownerToTokens;

    struct PriceChange {
        uint256 startTime;
        uint256 newPrice;
    }

    mapping(uint8 => PriceChange) private priceChange;

    struct NFTMetadata {
        /**
        _nftType:
        0 - Bronze
        1 - Silver
        2 - Gold
         */
        uint8 _nftType;
    }

    uint256[] private mintedBronze;
    uint256[] private mintedSilver;
    uint256[] private mintedGold;
    uint256[] private stolenNFTs;
    uint256[] private pendingStolenNFTs;

    // Token name
    string private _name = 'BABYX NFT';

    // Token symbol
    string private _symbol = 'xNFT';

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    uint256 private _totalSupply = 2000;
    uint256 private _totalSilver = 500;
    uint256 private _totalGold = 120;
    uint256 private _enteredSilver;
    uint256 private _enteredGold;
    uint256 private _circulatingSupply;

    uint256 private _startSteal;

    mapping(uint256 => NFTMetadata) private _nftMetadata;

    address stakingContract;

    bool public _revealed;

    string private baseURI;
    string private notRevealedURI;

    uint256 private gen0Price = 300 * 10 ** 18;
    // Address of BABYX Token
    IERC20 public Token;

    event NFTStolen(uint256 tokenId);

    modifier onlyStaking() {
        require(_msgSender() == stakingContract);
        _;
    }

    constructor(IERC20 _token) {
        Token = _token;
    }

    function getNumOfMintedBronze() public view returns (uint256) {
        return mintedBronze.length;
    }

    function getNumOfMintedSilver() public view returns (uint256) {
        return mintedSilver.length;
    }

    function getNumOfMintedGold() public view returns (uint256) {
        return mintedGold.length;
    }

    function getNFTRarity(uint256 tokenID) external view virtual returns (uint8) {
        require(_revealed, 'Tokens were not yet revealed');
        require(_exists(tokenID), 'Token does not exist');
        return (_nftMetadata[tokenID]._nftType);
    }

    function getMintedBronze() external view returns (uint256[] memory) {
        return mintedBronze;
    }

    function getMintedSilver() external view returns (uint256[] memory) {
        return mintedSilver;
    }

    function getMintedGold() external view returns (uint256[] memory) {
        return mintedGold;
    }

    function getStolenNFTs() external view returns (uint256) {
        return stolenNFTs.length;
    }

    function mint(uint256 _amount) external {
        require(_circulatingSupply + _amount <= 2000, 'All tokens were minted');
        uint256 price = _getCurrentPrice();
        Token.safeTransferFrom(_msgSender(), address(0), _amount * price);
        for (uint256 i; i < _amount; i++) {
            _circulatingSupply++;
            _safeMint(_msgSender(), _circulatingSupply);
            if (_circulatingSupply == 3) {
                _startFarming();
            }
        }
    }

    function retrieveFunds() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// @dev onlyOwner Functions
    function changeMintPriceTimeX(uint256 newPrice, uint256 startTime) external onlyOwner {
        if (startTime == 0) {
            startTime = block.timestamp;
        }
        priceChange[0].startTime = startTime;
        priceChange[0].newPrice = newPrice * 10 ** 18;
    }

    function changeMintPrice(uint256 _gen0Price) external onlyOwner {
        gen0Price = _gen0Price * 10 ** 18;
    }

    function setStartSteal(uint256 start) public onlyOwner {
        _startSteal = start;
    }

    function addGold(uint256[] memory _goldsIds) external onlyOwner {
        for (uint256 i; i < _goldsIds.length; i++) {
            _nftMetadata[_goldsIds[i]]._nftType = 2;
        }
        _enteredGold += _goldsIds.length;
        require(_enteredGold <= _totalGold, 'Gold amount would be exceeded');
    }

    function addSilver(uint256[] memory _silversIds) external onlyOwner {
        for (uint256 i; i < _silversIds.length; i++) {
            _nftMetadata[_silversIds[i]]._nftType = 1;
        }
        _enteredSilver += _silversIds.length;
        require(_enteredSilver <= _totalSilver, 'Silver amount would be exceeded');
    }

    function reveal() external onlyOwner {
        _revealed = true;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _newNotRevealedURI) external onlyOwner {
        notRevealedURI = _newNotRevealedURI;
    }

    function setStakingContract(address _address) external onlyOwner {
        stakingContract = _address;
    }

    function withdrawAnyToken(IERC20 asset) external onlyOwner {
        asset.safeTransfer(owner(), asset.balanceOf(address(this)));
    }

    function _startFarming() internal {
        IStaking(stakingContract).startFarming(block.timestamp);
    }

    function getCurrentPrice() external view returns (uint256) {
        return _getCurrentPrice();
    }

    function _getCurrentPrice() internal view returns (uint256) {
        if (block.timestamp <= priceChange[0].startTime + 3600) {
            return priceChange[0].newPrice;
        } else {
            return gen0Price;
        }
    }

    function retrieveStolenNFTs() external onlyStaking returns (bool returned, uint256[] memory) {
        uint256[] memory transferredNFTs = new uint256[](pendingStolenNFTs.length);
        if (pendingStolenNFTs.length > 0) {
            for (uint256 i; i < pendingStolenNFTs.length; i++) {
                _transfer(address(this), stakingContract, pendingStolenNFTs[i]);
                transferredNFTs[i] = pendingStolenNFTs[i];
            }
            returned = true;
            delete pendingStolenNFTs;
        } else {
            returned = false;
        }
        return (returned, transferredNFTs);
    }

    /// @dev ERC721 Functions
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function cirulatingSupply() public view returns (uint256) {
        return _circulatingSupply;
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), 'ERC721: balance query for the zero address');
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), 'ERC721: owner query for nonexistent token');
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        if (_revealed) {
            string memory baseURI_ = _baseURI();
            return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, tokenId.toString())) : '';
        } else {
            return string(abi.encodePacked(notRevealedURI, tokenId.toString())); // if do not reveal delete tokenId.toString()
        }
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, 'ERC721: approval to current owner');

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            'ERC721: approve caller is not owner nor approved for all'
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), 'ERC721: approved query for nonexistent token');

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), 'ERC721: transfer caller is not owner nor approved');

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), 'ERC721: transfer caller is not owner nor approved');
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), 'ERC721: transfer to non ERC721Receiver implementer');
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), 'ERC721: operator query for nonexistent token');
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, '');
    }

    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            'ERC721: transfer to non ERC721Receiver implementer'
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), 'ERC721: mint to the zero address');
        require(!_exists(tokenId), 'ERC721: token already minted');

        if (_nftMetadata[tokenId]._nftType == 1) {
            mintedSilver.push(tokenId);
        } else if (_nftMetadata[tokenId]._nftType == 2) {
            mintedGold.push(tokenId);
        } else {
            mintedBronze.push(tokenId);
        }

        bool stolen;
        if (_circulatingSupply > 3) {
            stolen = _stealMint(tokenId);
        }

        if (stolen) {
            to = address(this);
        }

        _balances[to] += 1;
        _owners[tokenId] = to;

        _beforeTokenTransfer(address(0), to, tokenId);
        emit Transfer(address(0), to, tokenId);
    }

    function _stealMint(uint256 tokenId) internal virtual returns (bool stolen) {
        require(_circulatingSupply > 3, 'NFT can not steal');

        if (tokenId % 10 >= _startSteal && tokenId % 10 <= _startSteal + 1) {
            stolen = true;
            stolenNFTs.push(tokenId);
            pendingStolenNFTs.push(tokenId);
            emit NFTStolen(tokenId);
        } else {
            stolen = false;
        }
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, 'ERC721: transfer from incorrect owner');
        require(to != address(0), 'ERC721: transfer to the zero address');

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, 'ERC721: approve to caller');
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert('ERC721: transfer to non ERC721Receiver implementer');
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function getUserNFTIds(address user) public view returns (uint256[] memory) {
        return ownerToTokens[user].values();
    }

    function getUserMetadata(address user) public view returns (string[] memory) {
        string[] memory userMetadata = new string[](getUserNFTIds(user).length);
        for (uint256 i; i < getUserNFTIds(user).length; i++) {
            userMetadata[i] = tokenURI(getUserNFTIds(user)[i]);
        }
        return userMetadata;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {
        ownerToTokens[to].add(tokenId);
        ownerToTokens[from].remove(tokenId);
    }
}