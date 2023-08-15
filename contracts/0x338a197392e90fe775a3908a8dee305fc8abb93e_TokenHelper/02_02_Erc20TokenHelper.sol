// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
pragma experimental ABIEncoderV2;

import "./Erc20Token.sol";

/**
 * @title ERC20 Token Helper smart-contract
 * @dev ERC20 token Helper smart-contact helps to deploy ERC20 token and takes deployment fee 
 *      and send fee to feecollecter address.
 */
contract TokenHelper {

    uint256 public fee;
    address public feeCollector;

    event TokenLaunched(
        address indexed _token, 
        address indexed _deployerAddress
    );

	constructor(address _feeCollector, uint256 _fee) {
        require(_feeCollector != address(0x0), "Invalid _feeCollector!!");

        feeCollector = payable(_feeCollector);
        fee = _fee;
    }

    receive() external payable{}

    fallback() external payable {}

	function deployToken( 
                    string memory _name,
                    string memory _symbol,
                    uint256 _tokenTotalSupply,
                    uint256 _initialTax,
                    uint256 _finalTax,
                    address _marketingWallet,
                    string memory _website,
                    string memory _twitter,
                    string memory _telegram
	) external payable returns (address tokenAddr) {

        if (fee > 0) {
            require(msg.value >= fee, "enough deployment fee is not supplied");

            // send deployment fee to feecollected address;
            (bool sent, ) = feeCollector.call{value: msg.value}("");
            require(sent, "Failed to send Ether");
        }
        
        tokenAddr = address(new ERC20Token(_name,
                                        _symbol,
                                        _tokenTotalSupply,
                                        _initialTax,
                                        _finalTax,
                                        _marketingWallet,
                                        address(msg.sender),
                                        _website,
                                        _twitter,
                                        _telegram));
                                        
        require(tokenAddr != address(0), "Failed to create ERC20 token!!");

        emit TokenLaunched(tokenAddr, msg.sender);
    }
}