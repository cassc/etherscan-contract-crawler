// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

contract ShunaV2 is ERC721, ERC721Enumerable, Ownable {
    uint256 public mintSupply;
    uint256 public mintPrice;
    address public feeRecipient;
    string public baseUrl;
    mapping(uint256 => uint256) private tokenMatrix; // used during random-tokenId genearation
    using Counters for Counters.Counter;
    using Strings for uint256;
    uint256 public firstTokenId;
    Counters.Counter private _mintedAmt;

    uint256 public presaleEndTime;
    mapping(address => bool) public whitelistAccounts;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _firstTokenId,
        uint256 _mintSupply,
        uint256 _mintPrice,
        address _feeRecipient,
        string memory _baseUrl,
        uint256 _presaleEndTime
    ) ERC721(_name, _symbol) {
        firstTokenId = _firstTokenId;
        mintSupply = _mintSupply;
        mintPrice = _mintPrice;
        feeRecipient = _feeRecipient;
        baseUrl = _baseUrl;
        presaleEndTime = _presaleEndTime;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUrl;
    }

    /* Random index Logic
        - consider an array of size equal to mintSupply
        - get a random-idx by hashing multiple variables
        - swap random-idx_value with last-idx_value
        - use last-idx_value (which is random-number) as next tokenId
        - remove last-idx from array as it's value is already used
    */
    function _getRandomNumber(uint256 _minNum, uint256 _maxNum)
        private
        view
        returns (uint256)
    {
        // will return random number between _minNum to _maxNum (excluding _maxNum)

        uint256 _random1 = uint256(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    block.coinbase,
                    block.difficulty,
                    block.gaslimit,
                    block.timestamp
                )
            )
        ) % _maxNum;

        return _random1 + _minNum;
    }

    function _mintOne(address _to) private {
        uint256 _remainingAmt = mintSupply - _mintedAmt.current();
        require(_remainingAmt > 0, 'All tokens already minted');
        uint256 _maxIdx = _remainingAmt - 1 + firstTokenId;

        // randomIdx >= 0 && (randomIdx < _remaingingAmt, randomIdx <= _maxIdx)
        uint256 _randomIdx = _getRandomNumber(firstTokenId, _remainingAmt);

        uint256 _randomVal;

        // if tokenMatrix[_randomIdx] == 0, means it's value is _randomIdx itself
        if (tokenMatrix[_randomIdx] == 0) {
            _randomVal = _randomIdx;
        } else {
            _randomVal = tokenMatrix[_randomIdx];
        }

        // if tokenMatrix[_maxIdx] == 0, means it's value is _maxIdx itself
        if (tokenMatrix[_maxIdx] == 0) {
            tokenMatrix[_randomIdx] = _maxIdx;
        } else {
            tokenMatrix[_randomIdx] = tokenMatrix[_maxIdx];
        }

        _mintedAmt.increment();
        _safeMint(_to, _randomVal);
    }

    function safeMint(uint256 _quantity) public payable {
        require(_quantity <= 5, 'Cannot mint more than 5 at a time');

        if (block.timestamp < presaleEndTime) {
            require(whitelistAccounts[msg.sender], 'You are not whitelisted');
            uint256 _nftBal = IERC721(address(this)).balanceOf(msg.sender);
            require(
                _nftBal + _quantity <= 5,
                'You cannot mint more than 5 NFTs during presale'
            );
        }

        // transfer mint-balance to owner
        require(
            msg.value >= (mintPrice * _quantity),
            'Insufficient purchase amount'
        );
        payable(feeRecipient).transfer(address(this).balance);

        for (uint256 i = 0; i < _quantity; i++) {
            _mintOne(msg.sender);
        }
    }

    //------------------------------ADMIN-------------------------------------------

    function updateWhitelist(address[] calldata _accounts, bool _isAdd)
        external
        onlyOwner
    {
        if (_isAdd) {
            for (uint256 i = 0; i < _accounts.length; i++)
                whitelistAccounts[_accounts[i]] = true;
        } else {
            for (uint256 i = 0; i < _accounts.length; i++)
                whitelistAccounts[_accounts[i]] = false;
        }
    }

    function updatePresaleEndTime(uint256 _presaleEndTime) external onlyOwner {
        presaleEndTime = _presaleEndTime;
    }

    function updateMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function updateFeeRecipient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
    }

    function updateBaseUrl(string calldata _baseUrl) external onlyOwner {
        baseUrl = _baseUrl;
    }

    // The following functions are overrides required by Solidity ----------------------------------
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}