//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

import {CudosAccessControls} from "./CudosAccessControls.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CudosTokenRecovery {
    mapping(address => uint256) public whitelistedStakersAmount;
    uint256 constant MAX_ADDRESSES_BATCH = 4000;

    IERC20 public token;
    CudosAccessControls public accessControls;

    event StakersWhitelisted(address[] addresses, uint[] amounts);
    event TokensExtracted(address indexed user, uint256 amount);

    constructor (IERC20 _token, CudosAccessControls _accessControls){
        require(address(_token) != address(0), "CudosTokenRecovery: Token address cannot be zero");
        require(address(_accessControls) != address(0), "CudosTokenRecovery: CudosAccessControls address cannot be zero");
        token = _token;
        accessControls = _accessControls;
    }

    function extractTokens() public {
        uint256 stakerAmmount = whitelistedStakersAmount[msg.sender];

        require(stakerAmmount > 0, "CudosTokenRecovery.extractTokens: Address is not whitelisted for token recovery");

        whitelistedStakersAmount[msg.sender] = 0;
        require(token.transfer(msg.sender, stakerAmmount),
            "CudosTokenRecovery.extractTokens: Token transfer is unsuccessful");

        emit TokensExtracted(msg.sender, stakerAmmount);
    }
    
    function setWhitelistedStakers(address[] calldata _addresses, uint256[] calldata _amounts) public {
        require(accessControls.hasAdminRole(msg.sender), "CudosTokenRecovery.setWhitelistedStakers: Only admin");
        require(_addresses.length == _amounts.length,
            "CudosTokenRecovery.setWhitelistedStakers: Number of addresses must match the number of amounts");
        require(_addresses.length <= MAX_ADDRESSES_BATCH,
            "CudosTokenRecovery.setWhitelistedStakers: Cannot whitelist more than 4000 addresses at a time");

        for(uint i; i < _addresses.length; i++){
            whitelistedStakersAmount[_addresses[i]] = _amounts[i];
        }

        emit StakersWhitelisted(_addresses, _amounts); 
    }
}