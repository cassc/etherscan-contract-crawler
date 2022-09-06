// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./lib/ERC721A.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "solmate/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

error FailedTransfer();
error ExceedsMaxSupply();
error BeforeSaleStart();
error AfterSaleEnd();
error NonTransferable();

contract OctavMembershipBeta is ERC721A, Ownable, ReentrancyGuard {
    address constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    IERC20 usdc = IERC20(USDC_ADDRESS);
    IERC20 dai = IERC20(DAI_ADDRESS);

    struct SaleConfig {
        uint64 usdcPrice;
        uint96 daiPrice;
        uint32 maxSupply;
        uint32 startTime;
        uint32 endTime;
    }

    SaleConfig public saleConfig;

    string public baseURI;

    constructor() ERC721A("OctavBeta", "OCTB") {
        saleConfig.usdcPrice = 250000000; 
        saleConfig.daiPrice = 250 ether; 
        saleConfig.maxSupply = 100; 
        saleConfig.startTime = 1664596800; 
        saleConfig.endTime = 1675227600; 
    }

    function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return baseURI; 
    }

    function updateBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function updateMaxSupply(uint32 _maxSupply) external onlyOwner {
        saleConfig.maxSupply = _maxSupply;
    }

    function updateStartTime(uint32 _startTime) external onlyOwner {
        saleConfig.startTime = _startTime;
    }

    function updateEndTime(uint32 _endTime) external onlyOwner {
        saleConfig.endTime = _endTime;
    }

    function updateUSDCPrice(uint64 _price) external onlyOwner {
        saleConfig.usdcPrice = _price;
    }

    function updateDAIPrice(uint96 _price) external onlyOwner {
        saleConfig.daiPrice = _price;
    }

    function mintOctavMembershipUSDC(uint256 _amount) external payable {
        SaleConfig memory sConfig = saleConfig;

        // Sale config
        uint256 _price = uint256(sConfig.usdcPrice);
        uint256 _maxSupply = uint256(sConfig.maxSupply);
        uint256 _startTime = uint256(sConfig.startTime);
        uint256 _endTime = uint256(sConfig.endTime);

        // Sale Config Reverts
        if (_currentIndex + _amount > _maxSupply) revert ExceedsMaxSupply();
        if (block.timestamp < _startTime) revert BeforeSaleStart();
        if (block.timestamp > _endTime) revert AfterSaleEnd();

        uint256 value = _price * _amount;

        // Transfer USDC
        bool success = usdc.transferFrom(msg.sender, address(this), value);
        if (!success) revert FailedTransfer();

        _safeMint(msg.sender, _amount);
    }

    function mintOctavMembershipDAI(uint256 _amount) external payable {
        SaleConfig memory sConfig = saleConfig;

        // Sale config
        uint256 _price = uint256(sConfig.daiPrice);
        uint256 _maxSupply = uint256(sConfig.maxSupply);
        uint256 _startTime = uint256(sConfig.startTime);
        uint256 _endTime = uint256(sConfig.endTime);

        // Sale Config Reverts
        if (_currentIndex + _amount > _maxSupply) revert ExceedsMaxSupply();
        if (block.timestamp < _startTime) revert BeforeSaleStart();
        if (block.timestamp > _endTime) revert AfterSaleEnd();

        uint256 value = _price * _amount;

        // Transfer DAI
        bool success = dai.transferFrom(msg.sender, address(this), value);
        if (!success) revert FailedTransfer();

        _safeMint(msg.sender, _amount);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        virtual
        override
    {
        revert NonTransferable();
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        virtual
        override
    {
        revert NonTransferable();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    )
        public
        virtual
        override
    {
        revert NonTransferable();
    }

    function tokenCreatedDate(uint256 tokenId) external view returns (uint64) {
        TokenOwnership storage ownership = _ownerships[tokenId];
        return ownership.startTimestamp;
    }

    function withdraw() external onlyOwner {
        (bool success,) =
            payable(msg.sender).call{value: address(this).balance}("");
        if (!success) revert FailedTransfer();
    }

    function withdrawERC20(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 erc20Balance = token.balanceOf(address(this));
        token.transfer(msg.sender, erc20Balance);
    }
}