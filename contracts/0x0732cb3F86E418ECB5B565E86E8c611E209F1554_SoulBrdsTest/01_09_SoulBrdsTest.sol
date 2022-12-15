// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/****************************************
 * @author: @itsanishjain
 ****************************************/

import {BaseOperator} from "./BaseOperator.sol";

contract SoulBrdsTest is BaseOperator {
    uint256 constant bps = 500;
    address devAddress = 0xcEA4225CC9f569946C1BFC6A7F0a6eEaC104A040;
    uint256 public maxSupply = 500;
    uint256 public maxPerTx = 446;
    uint256 public publicPrice = 0.45 ether;
    string public baseTokenURI;
    string public uriSuffix = "";
    bool public paused;

    modifier onlyWhenNotPaused() {
        require(paused, "Paused");
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "NonEOA");
        _;
    }

    constructor(string memory _baseTokenURI, address _treasury) {
        baseTokenURI = _baseTokenURI;
        _mint(_treasury, 54);
    }

    function publicMint(uint256 quantity)
        external
        payable
        onlyWhenNotPaused
        callerIsUser
    {
        require(quantity <= maxPerTx, "ExceededMaxPerTx");

        require(_totalMinted() + quantity <= maxSupply, "SupplyExceeded");

        require(msg.value >= publicPrice * quantity, "InvalidEtherAmount");

        _mint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "InvalidTokenId");

        string memory baseURI = _baseURI();

        return string(abi.encodePacked(baseURI, _toString(tokenId), uriSuffix));
    }

    // OWNER FUNCTIONS

    function mintMany(address[] calldata _to, uint256[] calldata _amount)
        external
        onlyOwner
    {
        for (uint256 i; i < _to.length; ) {
            _mint(_to[i], _amount[i]);
            unchecked {
                i++;
            }
        }
    }

    function withdraw() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        // 5 % sends to dev account
        require((totalBalance * bps) >= 10_000, "Withdraw not possible");
        uint256 devAmount = (totalBalance * bps) / 10_000;

        (bool success1, ) = devAddress.call{value: devAmount}("");
        (bool success2, ) = msg.sender.call{value: (totalBalance - devAmount)}(
            ""
        );
        require(success1 && success2, "WithdrawFailed");
    }

    function setPaused(bool _pasused) public onlyOwner {
        paused = _pasused;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setUriSuffix(string memory _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPublicPrice(uint256 _price) external onlyOwner {
        publicPrice = _price;
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_totalMinted() > _maxSupply, "InvalidMaxSupply");
        maxSupply = _maxSupply;
    }

    receive() external payable {}

    fallback() external payable {}
}