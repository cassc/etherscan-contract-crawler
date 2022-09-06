// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./helpers/FlashLoanReceiverBase.sol";
import "./interfaces/IWETH.sol";

//"0xe7acab24000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000005a00000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f000000000000000000000000000012f95747e78c6044a7cbb4670195103a660cfa4700000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000046000000000000000000000000000000000000000000000000000000000000004e00000000000000000000000006ea4ea5c3cd5c1f77f9d2114659cbacaea97edb7000000000000000000000000004c00500000ad104d7dbd00e3ae0a5c00560c0000000000000000000000000000000000000000000000000000000000000001600000000000000000000000000000000000000000000000000000000000000220000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000630875ce0000000000000000000000000000000000000000000000000000000063314fc90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002a3476171f965b0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000200000000000000000000000006012c8cf97bead5deae237070f9587f8e7a266d00000000000000000000000000000000000000000000000000000000001eb8aa0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008a8e4b1a3d8000000000000000000000000000000000000000000000000000008a8e4b1a3d80000000000000000000000000006ea4ea5c3cd5c1f77f9d2114659cbacaea97edb70000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000038d7ea4c6800000000000000000000000000000000000000000000000000000038d7ea4c680000000000000000000000000000000a26b00c1f0df003000390027140000faa7190000000000000000000000000000000000000000000000000000000000000041e56d886229514f8b2acd190c5fc3cef291a9b888271950a5038fd1420b4d72a06d88e3a9aed12c0b290c50c3d3962551637b5cd66107da6baba364b7ff928ff91b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

contract Buyer is FlashLoanReceiverBase, Ownable, ERC721Holder, ERC165 {
    address public constant SEAPORT =
        0x00000000006c3852cbEf3e08E8dF289169EdE581;
    address public constant OPENSEA_CONDUIT =
        0x1E0049783F008A0085193E00003D00cd54003c71;
    IWETH weth;
    address seller;
    bytes openseaTransactionData;

    event FlashloanGranted(address seller, address provider, uint256 amount);

    constructor(ILendingPoolAddressesProvider provider, IWETH weth_)
        FlashLoanReceiverBase(provider)
    {
        weth = weth_;
        weth.approve(OPENSEA_CONDUIT, 10e10 ether);
    }

    event Received(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        emit FlashloanGranted(seller, initiator, amounts[0]);
        //
        // This contract now has the funds requested.
        // Your logic goes here.
        //

        // At the end of your logic above, this contract owes
        // the flashloaned amounts + premiums.
        // Therefore ensure your contract has enough to repay
        // these amounts.

        // buy the nft from opensea
        // weth.transfer(seller, amounts[0] - openseaFees);

        // purchase nft from opensea
        (bool success, ) = SEAPORT.call(openseaTransactionData);
        require(success, "opensea transaction failed");

        uint256 openseaFees = (amounts[0] * 25) / 10000;

        // after buying the nft from opensea get the amount from the seller using pre approved manner
        weth.transferFrom(seller, address(this), amounts[0] - openseaFees);

        // Approve the LendingPool contract allowance to *pull* the owed amount
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 amountOwing = amounts[i] + premiums[i];
            IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
        }

        return true;
    }

    function myFlashLoanCall(
        address seller_,
        bytes calldata openseaTransactionData_,
        uint256 amount
    ) public {
        seller = seller_;
        openseaTransactionData = openseaTransactionData_;
        address receiverAddress = address(this);

        address[] memory assets = new address[](1);
        assets[0] = address(weth);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        address onBehalfOf = address(this);
        bytes memory params = "";
        uint16 referralCode = 0;

        LENDING_POOL.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }

    function withdraw() public onlyOwner {
        uint256 balance = weth.balanceOf(address(this));
        weth.transfer(msg.sender, balance);
    }

    // function completeOrder(bytes memory data) public payable {
    //     (bool success, ) = SEAPORT.call{value: msg.value}(data);
    //     require(success, "transaction failed");
    // }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IERC721Receiver).interfaceId;
    }
}