//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import {DefaultOperatorFiltererUpgradeable} from "./DefaultOperatorFiltererUpgradeable.sol";
import "./IERC20Permit.sol";
import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract WOW is
    ERC721AUpgradeable,
    OwnableUpgradeable,
    ERC2981Upgradeable,
    DefaultOperatorFiltererUpgradeable,
    UUPSUpgradeable
{
    IERC20Permit USDCAddress;
    uint256 public MAX_SUPPLY;
    uint256 public TOTAL_SUPPLY;
    string public baseURI;
    bool public pausedUSDCMint;
    bool public pausedETHMint;

    uint256[] public CostUSDC;
    uint256[] public CostETH;

    function initialize(
        string memory name,
        string memory symbol,
        IERC20Permit _USDC
    ) public initializerERC721A initializer {
        __ERC721A_init(name, symbol);
        __Ownable_init();
        __ERC2981_init();
        __DefaultOperatorFilterer_init();
        __UUPSUpgradeable_init();

        USDCAddress = _USDC;
        _setDefaultRoyalty(msg.sender, 1000);
        MAX_SUPPLY = 9888;
        TOTAL_SUPPLY = 988;
        baseURI = "ipfs://QmXhSRxuu4AkjbNUZaAEbAobYaUkFs5JgCkDHtWPp7VhQf/";
        pausedUSDCMint = true;
        pausedETHMint = true;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    modifier checksBeforeMint(uint256 quantity) {
        require(pausedETHMint == false, "Function Paused");
        require(quantity > 0, "Not enough quantity to mint");
        require(
            totalSupply() + quantity <= TOTAL_SUPPLY,
            "Not enough tokens left"
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Not enough tokens left"
        );
        require(CostETH.length != 0, "Owner didnot set price yet");
        require(
            msg.value >= _discountNFTPrice(quantity, 1),
            "Not enough ether sent"
        );
        _;
    }

    modifier checksBeforeMintUSDC(uint256 quantity) {
        require(pausedUSDCMint == false, "Function Paused");
        require(quantity > 0, "Not enough quantity to mint");
        require(
            totalSupply() + quantity <= TOTAL_SUPPLY,
            "Not enough tokens left"
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Not enough tokens left"
        );
        require(CostUSDC.length != 0, "Owner didnot set price yet");
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function changeTotalSupply(uint256 _value) public onlyOwner {
        TOTAL_SUPPLY = _value;
    }

    function changePrice(uint256[] memory _updatedPrice, uint256 condition)
        public
        onlyOwner
    {
        require(_updatedPrice.length == 5, "Incorrect data");
        if (condition == 0) {
            CostUSDC = _updatedPrice;
        } else {
            CostETH = _updatedPrice;
        }
    }

    function updateRoyalty(uint96 _feeNumerator) public onlyOwner {
        _setDefaultRoyalty(msg.sender, _feeNumerator);
    }

    function changePauseState(bool _state, uint256 condition) public onlyOwner {
        if (condition == 0) {
            pausedUSDCMint = _state;
        } else {
            pausedETHMint = _state;
        }
    }

    function mintNFTwithUSDC(
        uint256 quantity,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public checksBeforeMintUSDC(quantity) {
        uint256 cost = _discountNFTPrice(quantity, 0);
        require(USDCAddress.balanceOf(msg.sender)>= cost, "Not enough USDC");
        USDCAddress.permit(msg.sender, address(this), cost, deadline, v, r, s);
        USDCAddress.transferFrom(msg.sender, address(this), cost);
        _safeMint(msg.sender, quantity);
    }

    function mintNFT(uint256 quantity)
        public
        payable
        checksBeforeMint(quantity)
    {
        _safeMint(msg.sender, quantity);
    }

    function _discountNFTPrice(uint256 _quantity, uint256 condition)
        internal
        view
        returns (uint256)
    {
        uint256 price;
        uint256[] memory price_arr;
        if (condition == 0) {
            price_arr = CostUSDC;
        } else {
            price_arr = CostETH;
        }
        if (_quantity <= 4) {
            price = price_arr[0];
        } else if (_quantity <= 9) {
            price = price_arr[1];
        } else if (_quantity <= 32) {
            price = price_arr[2];
        } else if (_quantity <= 99) {
            price = price_arr[3];
        } else {
            price = price_arr[4];
        }

        return (price * _quantity);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdrawUSDC() public payable onlyOwner {
        USDCAddress.transfer(msg.sender, USDCAddress.balanceOf(address(this)));
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}