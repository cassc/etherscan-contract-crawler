// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "./utils/GDXERC721Batch.sol";
import "./utils/Signed.sol";

contract K9 is GDXERC721Batch, Signed {
    using Strings for uint256;

    uint256 public MAX_ORDER = 8;
    uint256 public MAX_SUPPLY = 4444;
    uint256 public PRICE = 0.06 ether;

    uint256 public MAX_PRESALE_AMOUNT = 4;
    uint256 public PRESALE_PRICE = 0.05 ether;

    bool public isPresaleActive = false;
    bool public isVerified = true;
    bool public isMainsaleActive = false;

    string private _baseTokenURI = "";
    string private _tokenURISuffix = "";

    mapping(address => uint256) public presaleMap;

    address[] addresses = [
        0xb0C72ADfb17Ab00d4e78915F5DeD36345537b04E,
        0x0af53dB501Bb544f2A95477eA01615DFfe7C3D99,
        0x14B98AaeE41ACFED1D860a310AAcC32a3DDd8e9A,
        0xB7edf3Cbb58ecb74BdE6298294c7AAb339F3cE4a
    ];
    uint256[] splits = [73, 10, 10, 7];

    constructor() GDXERC721("K9", "K9") {}

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
    function mint(uint256 quantity, bytes calldata signature) external payable {
        require(quantity <= MAX_ORDER, "Order too big");

        uint256 supply = totalSupply();
        require(supply + quantity <= MAX_SUPPLY, "Mint/order exceeds supply");

        if (isMainsaleActive) {
            require(msg.value >= PRICE * quantity, "Ether sent is not correct");
            require(quantity <= MAX_ORDER, "Order too big");
        } else if (isPresaleActive) {
            require(
                msg.value >= PRESALE_PRICE * quantity,
                "Ether sent is not correct"
            );
            require(
                quantity + presaleMap[msg.sender] <= MAX_PRESALE_AMOUNT,
                "Order too big"
            );

            if (isVerified) verifySignature(quantity.toString(), signature);

            presaleMap[msg.sender] = presaleMap[msg.sender] + quantity;
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
        bool isPresaleActive_,
        bool isMainsaleActive_,
        bool isVerified_
    ) external onlyDelegates {
        if (isPresaleActive != isPresaleActive_)
            isPresaleActive = isPresaleActive_;

        if (isMainsaleActive != isMainsaleActive_)
            isMainsaleActive = isMainsaleActive_;

        if (isVerified != isVerified_) isVerified = isVerified_;
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