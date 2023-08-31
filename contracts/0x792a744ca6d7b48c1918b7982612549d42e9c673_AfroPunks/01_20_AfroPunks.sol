// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "./GDXERC721Batch.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AfroPunks is GDXERC721Batch {
    using Strings for uint256;

    uint256 public MAX_ORDER = 20;
    uint256 public MAX_SUPPLY = 3333;
    uint256 public PRICE = 0.033 ether;

    bool public isMainsaleActive = false;

    string private _baseTokenURI = "";
    string private _tokenURISuffix = "";

    mapping(address => uint256) public presaleMap;

    address[] addresses = [
        0x5478D62322328cb1FA565E8847eCcD5e3428480B,
		0xB7edf3Cbb58ecb74BdE6298294c7AAb339F3cE4a
    ];
    uint256[] splits = [90, 10];

    constructor() GDXERC721("AfroPunks", "AFPK") {}

    //safety first
    fallback() external payable {}

    receive() external payable {}

    function withdraw() external onlyDelegates {
        require(address(this).balance > 0);
        uint256 bal = address(this).balance;
        for (uint256 i; i < addresses.length; i++) {
            require(payable(addresses[i]).send((bal / 100) * splits[i]));
        }
    }

    //view
    function getTokensByOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        return walletOfOwner(owner);
    }

    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(
                    _baseTokenURI,
                    tokenId.toString(),
                    _tokenURISuffix
                )
            );
    }

    //payable
    function mint(uint256 quantity) external payable {
        require(quantity <= MAX_ORDER, "Order too big");

        uint256 supply = totalSupply();
        require(supply + quantity <= MAX_SUPPLY, "Mint/order exceeds supply");

        if (isMainsaleActive) {
            require(msg.value >= PRICE * quantity, "Ether sent is not correct");
            require(quantity <= MAX_ORDER, "Order too big");
        } else {
            revert("Sale is not active");
        }

        unchecked {
            for (uint256 i; i < quantity; i++) {
                _mint(msg.sender, supply++);
            }
        }
    }

    //onlyDelegates
    function mintTo(uint256[] calldata quantity, address[] calldata recipient)
        external
        payable
        onlyDelegates
    {
        require(
            quantity.length == recipient.length,
            "Must provide equal quantities and recipients"
        );

        uint256 totalQuantity;
        uint256 supply = totalSupply();
        for (uint256 i; i < quantity.length; i++) {
            totalQuantity += quantity[i];
        }
        require(
            supply + totalQuantity <= MAX_SUPPLY,
            "Mint/order exceeds supply"
        );

        unchecked {
            for (uint256 i = 0; i < recipient.length; i++) {
                for (uint256 j = 0; j < quantity[i]; j++) {
                    _mint(recipient[i], supply++);
                }
            }
        }
    }

    // In case of emergency
    function setWithdrawalData(
        address[] calldata _addr,
        uint256[] calldata _splits
    ) external onlyDelegates {
        require(
            _addr.length == splits.length,
            "Mismatched number of addresses and splits."
        );
        addresses = _addr;
        splits = _splits;
    }

    function setActive(
        bool isMainsaleActive_
    ) external onlyDelegates {

        if (isMainsaleActive != isMainsaleActive_)
            isMainsaleActive = isMainsaleActive_;

    }

    function setBaseURI(string calldata _newBaseURI, string calldata _newSuffix)
        external
        onlyDelegates
    {
        _baseTokenURI = _newBaseURI;
        _tokenURISuffix = _newSuffix;
    }

    function setMax(uint256 maxOrder, uint256 maxSupply)
        external
        onlyDelegates
    {
        require(
            maxSupply >= totalSupply(),
            "Specified supply is lower than current balance"
        );

        if (MAX_ORDER != maxOrder) MAX_ORDER = maxOrder;

        if (MAX_SUPPLY != maxSupply) MAX_SUPPLY = maxSupply;
    }

    function setPrice(uint256 price) external onlyDelegates {
        if (PRICE != price) PRICE = price;
    }

    //internal
    function _mint(address to, uint256 tokenId) internal override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }
}