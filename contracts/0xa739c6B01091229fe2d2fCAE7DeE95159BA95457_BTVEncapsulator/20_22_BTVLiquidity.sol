//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IBTVEncapsulator.sol";
import "./ICallable.sol";
import "./IWhitelist.sol";
import "hardhat/console.sol";

contract BTVLiquidity {
    address private _owner;

    // Mapping from ERC20 address to price in wei
    mapping(address => uint256) public ethPrice;
    mapping(address => uint256) public nxcPrices;
    // Mapping from asset to token to price
    mapping(IERC20 => mapping(IERC20 => uint256)) public tokenPrice;

    IBTVEncapsulator public encapsulator;
    IWhitelist private _whitelist;
    address public nexiumBurnAddress =
        0x1B32000000000000000000000000000000000000;
    address public nexiumAddress;
    bool whitelistForERC20 = false;

    modifier whitelisted(bool bypass) {
        require(
            bypass ||
            _whitelist == IWhitelist(address(0)) ||
                _whitelist.hasAccess(msg.sender) ||
                _whitelist.hasAccess(tx.origin),
            "No access"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner has permission");
        _;
    }

    constructor(address _nexiumContract) {
        _owner = msg.sender;
        nexiumAddress = _nexiumContract;
    }

    function setEncapsulator(IBTVEncapsulator _encapsulator) public onlyOwner {
        encapsulator = _encapsulator;
    }

    function setWhitelist(address whitelist) external onlyOwner {
        _whitelist = IWhitelist(whitelist);
    }

    function setWhitelistForERC20(bool whitelist) external onlyOwner {
        whitelistForERC20 = whitelist;
    }

    function withdrawToken(IERC20 token, uint256 amount) public onlyOwner {
        require(
            token.balanceOf(address(this)) >= amount,
            "Not enough balance to withdraw"
        );

        token.transfer(msg.sender, amount);
    }

    function withdrawEth(uint256 weiAmount) public onlyOwner {
        require(
            address(this).balance >= weiAmount,
            "Not enough balance to withdraw"
        );

        (bool success, ) = _owner.call{value: weiAmount}("");
        require(success, "Sending to owner unsucessful");
    }

    function listWithToken(
        IERC20 asset,
        IERC20 token,
        uint256 price
    ) public onlyOwner {
        tokenPrice[asset][token] = price;
    }

    function listWithEth(IERC20 asset, uint weiPrice) public onlyOwner {
        ethPrice[address(asset)] = weiPrice;
    }

    function buyWithEth(uint256 typeId, uint256 amount) public payable whitelisted(false) {
        IERC20 asset = IERC20(encapsulator.tokenContractOf(typeId));
        uint256 price = ethPrice[encapsulator.tokenContractOf(typeId)];

        require(price != 0, "Asset not listed");
        require(msg.value == price * amount, "Priced incorrectly");
        asset.approve(address(encapsulator), amount);
        encapsulator.swapForNFT(typeId, amount, msg.sender);
    }

    function buyWithToken(
        uint256 typeId,
        uint256 amount,
        IERC20 token,
        address buyer
    ) public whitelisted(!whitelistForERC20) {
        IERC20 asset = IERC20(encapsulator.tokenContractOf(typeId));
        uint256 price = amount * tokenPrice[asset][token];

        require(
            asset.balanceOf(address(this)) >= amount,
            "Not enough liquidity to purchase"
        );
        require(
            token.allowance(buyer, address(this)) >= price,
            "Not enough allowance to make purchase"
        );
        require(
            token.transferFrom(buyer, address(this), price),
            "Payment transfer failed"
        );
        asset.approve(address(encapsulator), amount);
        encapsulator.swapForNFT(typeId, amount, buyer);

        if (nexiumAddress == address(token))
            token.transfer(nexiumBurnAddress, price);
    }

    function feedLiquidity(uint256 amount, address contractAdress) internal {
        IERC20 token = IERC20(contractAdress);

        require(tx.origin == _owner, "Only owner can add liquidity");
        require(
            token.transferFrom(tx.origin, address(this), amount),
            "Failed getting tokens"
        );

        // token.approve(address(encapsulator), token.balanceOf(address(this)));
    }

    function _strcmp(string memory str1, string memory str2)
        internal
        pure
        returns (bool equal)
    {
        return (keccak256(abi.encodePacked(str1)) ==
            keccak256(abi.encodePacked(str2)));
    }

    function receiveApproval(
        address sender,
        uint256 amount,
        address _contract,
        bytes calldata _extraData
    ) public {
        require(
            _extraData.length == 128,
            "Liquidity: approveAndCall extra data is not 128"
        );
        (uint256 nb, string memory reason) = abi.decode(
            _extraData,
            (uint256, string)
        );

        if (_strcmp(reason, "feed")) {
            feedLiquidity(amount, _contract);
        } else if (_strcmp(reason, "buy")) {
            IERC20 asset = IERC20(encapsulator.tokenContractOf(nb));
            IERC20 token = IERC20(_contract);

            buyWithToken(nb, amount / tokenPrice[asset][token], token, sender);
        }
    }
}