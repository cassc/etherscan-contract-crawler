// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/**
 * @dev ERC1155NFTBase contract.
 * @notice Setup admin control functional, include price,
 */
contract ERC1155NFTBase is Ownable, ERC1155 {
    // status of contract
    enum STATUS {
        OFF_SALE,
        PRE_SALE,
        ON_SALE
    }

    enum STAGE {
        STAGE_1,
        STAGE_2,
        STAGE_3,
        SOLD_ALL
    }

    // index of next token aka number of token was minted
    uint256 private _nextIndex;

    // maximum token can be minted
    uint256 public TOTAL_SUPPLY;

    // maximum token can be minted per wallet
    uint256 public maxMint;
    uint256 public price;

    // URI of token before reveal
    string internal blankURI;

    string internal baseMetadataURI;

    STATUS public status;
    STAGE public stage;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public counter;

    constructor(
        string memory _blankURI,
        uint256 _supply,
        uint256 _price,
        uint256 _maxMint
    ) public ERC1155(_blankURI) {
        _nextIndex = 0;
        TOTAL_SUPPLY = _supply;
        price = _price;
        maxMint = _maxMint;
        blankURI = _blankURI;
        stage = STAGE.STAGE_1;
    }

    /**
     * @dev ensure collector pays for mint token
     */
    modifier mintable(uint256 _number) {
        require(
            _number.add(nextIndex()) <= TOTAL_SUPPLY,
            "Bound limit of maximum supply limit"
        );
        _;
    }

    /**
     * @dev next token index.
     */
    function nextIndex() public view virtual returns (uint256) {
        return _nextIndex;
    }

    /**
     * @dev change status from online to offline and vice versa
     */
    function setStatus(STATUS _status) public onlyOwner returns (bool) {
        status = _status;
        return true;
    }

    function setStatusWithPriceAndMaxMint(
        STATUS _status,
        uint256 _price,
        uint256 _maxMint
    ) public onlyOwner returns (bool) {
        status = _status;
        price = _price;
        maxMint = _maxMint;
        return true;
    }

    function setStage(STAGE _stage) public onlyOwner returns (bool) {
        stage = _stage;
        return true;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setMaxMint(uint256 _maxMint) external onlyOwner {
        maxMint = _maxMint;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseMetadataURI = _baseURI;
    }

    function setBlankURI(string memory _blankURI) public onlyOwner {
        blankURI = _blankURI;
    }

    function addToWhitelist(address[] memory _wallets) public onlyOwner {
        for (uint256 i = 0; i < _wallets.length; ++i) {
            whitelist[_wallets[i]] = true;
        }
    }

    function removeFromWhitelist(address[] memory _wallets) public onlyOwner {
        for (uint256 i = 0; i < _wallets.length; ++i) {
            whitelist[_wallets[i]] = false;
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _mintToken(address _receiver, uint256 _number) internal {
        if (stage == STAGE.STAGE_1) {
            require(
                _number.add(nextIndex()) <= 2000,
                "Bound limit of maximum supply of Stage 1"
            );
        }
        if (stage == STAGE.STAGE_2) {
            require(
                _number.add(nextIndex()) <= 6000,
                "Bound limit of maximum supply of Stage 2"
            );
        }
        uint256[] memory ids = new uint256[](_number);
        uint256[] memory amounts = new uint256[](_number);

        for (uint256 i = 0; i < _number; i++) {
            ids[i] = nextIndex();
            amounts[i] = 1;
            _nextIndex = _nextIndex.add(1);
        }

        _mintBatch(_receiver, ids, amounts, "");

        counter[_receiver] = counter[_receiver].add(_number);
    }

    function _mintOnSale(address _receiver, uint256 _numTokensToMint) internal {
        require(status == STATUS.ON_SALE, "Status is not on sale");
        require(msg.value >= _numTokensToMint.mul(price), "Payment error");
        require(
            _numTokensToMint.add(counter[_receiver]) <= maxMint,
            "Over max token can mint per wallet"
        );

        _mintToken(_receiver, _numTokensToMint);
    }

    function _mintPreSale(address _receiver, uint256 _numTokensToMint)
        internal
    {
        require(status == STATUS.PRE_SALE, "Status is not preSale");
        require(whitelist[_receiver], "You are not in whitelist");
        require(msg.value >= _numTokensToMint.mul(price), "Payment error");
        require(
            _numTokensToMint.add(counter[_receiver]) <= maxMint,
            "Over max token can mint per wallet"
        );

        _mintToken(_receiver, _numTokensToMint);
    }
}