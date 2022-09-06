//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import './royalties/contracts/LibRoyaltiesV2.sol';
import './royalties/contracts/impl/RoyaltiesV2Impl.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import 'erc721a/contracts/ERC721A.sol';
import 'erc721a/contracts/extensions/ERC721ABurnable.sol';

/***********************************************************************************************
 ***********************************************************************************************

___________            __                       __              _____
\_   _____/___________/  |_ __ __  ____ _____ _/  |_  ____     /  _  \ ______   ____   ______
 |    __)/  _ \_  __ \   __\  |  \/    \\__  \\   __\/ __ \   /  /_\  \\____ \_/ __ \ /  ___/
 |     \(  <_> )  | \/|  | |  |  /   |  \/ __ \|  | \  ___/  /    |    \  |_> >  ___/ \___ \
 \___  / \____/|__|   |__| |____/|___|  (____  /__|  \___  > \____|__  /   __/ \___  >____  >
     \/                               \/     \/          \/          \/|__|        \/     \/


***********************************************************************************************
***********************************************************************************************/

contract CustomERC721A is
    ERC721A,
    ERC721ABurnable,
    Ownable,
    ReentrancyGuard,
    RoyaltiesV2Impl
{
    struct Winner {
        address wallet;
        uint256 position;
        uint256 tokenId;
        uint256 timestamp;
    }

    bytes4 internal constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    address payable public constant _ROYALTIES_WALLET =
        payable(0xce7d992a21f2FA078940b60632b481018D3bE752);

    uint96 public constant _ROYALTIES_PERCENTAGE = 1000;

    uint256 public constant _MINT_PRICE = 0.02 ether;
    uint256 public constant _MAX_SUPPLY = 7000;

    uint256 public constant _MAX_TOKENS_PER_TX = 25;
    uint256 public constant _MAX_TOKENS_PER_WHITELIST_TX = 2;
    uint256 public constant _MAX_TOKENS_PER_WHITELIST_WALLET = 6;

    bool private _paused = true;
    bool private _burnPaused = false;

    mapping(address => bool) private _whitelist;
    mapping(address => bool) private _hasClaimedWhitelist;

    bool private _publicOpen = false;
    bool private _whitelistOpen = false;

    string private _url = '';

    mapping(uint256 => Winner[]) private _raffle_winners;
    uint256[] private _raffle_timestamps;
    uint256 private _last_raffle_timestamp;

    constructor() ERC721A('FortunateApes', 'FAFM') {}

    // MODIFIERS
    modifier callerIsUser() {
        require(tx.origin == msg.sender, 'The caller is another contract');
        _;
    }

    modifier publicOpen() {
        require(_publicOpen, 'Public sale not yet available');
        _;
    }

    modifier whitelistOpen() {
        require(_whitelistOpen, 'Whitelist sale not yet available');
        _;
    }

    modifier onlyWhitelisted() {
        require(_whitelist[msg.sender] == true, 'You are not whitelisted');
        _;
    }

    // MINTING
    function mint(uint256 _mintAmount)
        external
        payable
        callerIsUser
        publicOpen
    {
        require(!_paused, 'The contract is paused');
        require(
            _mintAmount <= _MAX_TOKENS_PER_TX,
            'Maximum allowed tokens per transaction exceeded'
        );
        require(
            totalSupply() + _mintAmount * 2 <= _MAX_SUPPLY,
            'Token supply exceeded'
        );
        require(msg.value >= (_MINT_PRICE * _mintAmount), 'Insufficient funds');

        _safeMint(msg.sender, _mintAmount * 2, '');
    }

    function whitelistMint(uint256 _mintAmount)
        external
        payable
        callerIsUser
        whitelistOpen
        onlyWhitelisted
    {
        require(!_paused, 'The contract is paused');
        require(
            balanceOf(msg.sender) + _mintAmount <=
                _MAX_TOKENS_PER_WHITELIST_WALLET,
            'You have exceeded the number of tokens per whitelist user'
        );
        require(
            _mintAmount > 0 || !_hasClaimedWhitelist[msg.sender],
            'You have already claimed your free tokens'
        );

        if (_mintAmount > 0) {
            require(
                _mintAmount <= _MAX_TOKENS_PER_WHITELIST_TX,
                'Maximum allowed tokens per transaction exceeded'
            );

            require(
                totalSupply() + _mintAmount * 2 <= _MAX_SUPPLY,
                'Whitelist token supply exceeded'
            );

            require(
                msg.value >= (_MINT_PRICE * _mintAmount),
                'Insufficient funds'
            );

            _safeMint(msg.sender, _mintAmount * 2, '');
        }

        require(
            totalSupply() + _mintAmount * 2 < _MAX_SUPPLY,
            'Whitelist token supply exceeded'
        );

        if (!_hasClaimedWhitelist[msg.sender]) {
            _safeMint(msg.sender, 2, '');
            _hasClaimedWhitelist[msg.sender] = true;
        }
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount, '');
    }

    function burn(uint256 _tokenId) public virtual override {
        require(!_burnPaused, 'You cannot burn while minting');
        _burn(_tokenId, true);
    }

    function raffle(uint256 _winnerAmount) public onlyOwner returns (uint256) {
        uint256[] memory _range = _rangeArray(totalSupply());
        uint256[] memory _shuffled = _shuffle(_range);
        uint256 _timestamp = block.timestamp;
        uint256 _position = 1;

        for (uint256 i = 0; i < _winnerAmount; i++) {
            uint256 random = uint256(
                keccak256(abi.encodePacked(block.timestamp, msg.sender))
            ) % (_shuffled.length - i);

            while (_shuffled[random] == 0) {
                random > totalSupply() / 2 ? random-- : random++;
            }

            uint256 _tokenId = _shuffled[random];
            Winner memory winner = Winner(
                ownerOf(_tokenId),
                _position,
                _tokenId,
                _timestamp
            );

            _position++;
            _raffle_winners[_timestamp].push(winner);
            _shuffled[random] = 0;
        }

        _raffle_timestamps.push(_timestamp);
        _last_raffle_timestamp = _timestamp;
        return _timestamp;
    }

    // UTILS
    function openWhitelist() public onlyOwner {
        _whitelistOpen = true;
    }

    function closeWhitelist() public onlyOwner {
        _whitelistOpen = false;
    }

    function isWhitelistOpen() public view returns (bool) {
        return _whitelistOpen;
    }

    function openPublic() public onlyOwner {
        _publicOpen = true;
    }

    function closePublic() public onlyOwner {
        _publicOpen = false;
    }

    function isPublicOpen() public view returns (bool) {
        return _publicOpen;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}('');
        require(success, 'Transfer failed');
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            'ERC721Metadata: URI query for nonexistent token'
        );
        string memory _currentBaseURI = _baseURI();

        return
            bytes(_currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        _currentBaseURI,
                        _toString(_tokenId),
                        '.json'
                    )
                )
                : '';
    }

    function _shuffle(uint256[] memory _array)
        private
        view
        returns (uint256[] memory)
    {
        for (uint256 i = 0; i < _array.length; i++) {
            uint256 n = i +
                (uint256(keccak256(abi.encodePacked(block.timestamp))) %
                    (_array.length - i));
            uint256 temp = _array[n];
            _array[n] = _array[i];
            _array[i] = temp;
        }

        return _array;
    }

    function _rangeArray(uint256 _maxAmount)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory _array = new uint256[](_maxAmount);
        for (uint256 i = 0; i < _maxAmount; i++) {
            _array[i] = i + 1;
        }

        return _array;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _url;
    }

    // GETTERS & SETTERS
    function getBaseURI() public view onlyOwner returns (string memory) {
        return _url;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _url = _uri;
    }

    function getPaused() public view returns (bool) {
        return (_paused);
    }

    function setPaused(bool _state) public onlyOwner {
        _paused = _state;
    }

    function getBurnPaused() public view returns (bool) {
        return (_burnPaused);
    }

    function setBurnPaused(bool _state) public onlyOwner {
        _burnPaused = _state;
    }

    function isPaused() public view returns (bool) {
        return _paused;
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return _whitelist[_address];
    }

    function setWhitelistAddresses(address[] memory _addresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _whitelist[_addresses[i]] = true;
        }
    }

    function getRaffleTimestamps() public view returns (uint256[] memory) {
        return _raffle_timestamps;
    }

    function getWinnersByTimestamp(uint256 _timestamp)
        public
        view
        returns (Winner[] memory)
    {
        bool exists = false;
        for (uint256 i = 0; i < _raffle_timestamps.length; i++) {
            if (i == _timestamp) exists = true;
        }
        require(!exists, 'No raffle for provided timestamp');
        return _raffle_winners[_timestamp];
    }

    function getLastRaffleTimestamp() public view returns (uint256) {
        return _last_raffle_timestamp;
    }

    // ROYALTIES
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        uint256 _endTokenId = startTokenId + quantity;
        for (uint256 i = startTokenId; i < _endTokenId; i++) {
            _setRoyalties(i, _ROYALTIES_WALLET, _ROYALTIES_PERCENTAGE);
        }
    }

    function _setRoyalties(
        uint256 _tokenId,
        address payable _royaltiesRecipientAddress,
        uint96 _percentageBasisPoints
    ) internal {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesRecipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        LibPart.Part[] memory _royalties = royalties[_tokenId];

        if (_royalties.length > 0) {
            return (
                _royalties[0].account,
                (_salePrice * _royalties[0].value) / 10000
            );
        }

        return (address(0), 0);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A)
        returns (bool)
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }

        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }

        return super.supportsInterface(interfaceId);
    }
}