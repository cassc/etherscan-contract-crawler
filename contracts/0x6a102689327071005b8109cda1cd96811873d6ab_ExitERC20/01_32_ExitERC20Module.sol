// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./ExitBase.sol";
import "../CirculatingSupply/CirculatingSupplyERC20.sol";

contract ExitERC20 is ExitBase, ReentrancyGuard {
    using SafeERC20 for ERC20;

    ERC20 public designatedToken;
    CirculatingSupplyERC20 public circulatingSupply;

    // @dev Initialize function, will be triggered when a new proxy is deployed
    // @param _owner Address of the owner
    // @param _avatar Address of the avatar (e.g. a Safe or Delay Module)
    // @param _target Address that this module will pass transactions to
    // @param _designatedToken Address of the ERC20 token that will define the share of users
    // @param _circulatingSupply Circulating Supply of designated token
    // @notice Designated token address can not be zero
    constructor(
        address _owner,
        address _avatar,
        address _target,
        address _designatedToken,
        address _circulatingSupply
    ) {
        bytes memory initParams = abi.encode(
            _owner,
            _avatar,
            _target,
            _designatedToken,
            _circulatingSupply
        );
        setUp(initParams);
    }

    function setUp(bytes memory initParams) public override {
        (
            address _owner,
            address _avatar,
            address _target,
            address _designatedToken,
            address _circulatingSupply
        ) = abi.decode(
                initParams,
                (address, address, address, address, address)
            );
        __Ownable_init();
        require(_avatar != address(0), "Avatar can not be zero address");
        require(_target != address(0), "Target can not be zero address");
        avatar = _avatar;
        target = _target;
        designatedToken = ERC20(_designatedToken);
        circulatingSupply = CirculatingSupplyERC20(_circulatingSupply);

        transferOwnership(_owner);

        emit ExitModuleSetup(msg.sender, _avatar);
    }

    // @dev Execute the share of assets and the transfer of designated tokens
    // @param amountToRedeem Amount to be sent to the avatar
    // @param tokens Array of tokens to claim, ordered lowest to highest
    // @notice Will revert if tokens[] is not ordered highest to lowest, contains duplicates,
    //         includes the designated token or includes denied tokens
    function exit(uint256 amountToRedeem, address[] calldata tokens)
        external
        override
        nonReentrant
    {
        require(
            designatedToken.balanceOf(msg.sender) >= amountToRedeem,
            "Amount to redeem is greater than balance"
        );

        for (uint8 i = 0; i < tokens.length; i++) {
            require(
                tokens[i] != address(designatedToken),
                "Designated token can't be redeemed"
            );
        }

        bytes memory params = abi.encode(
            amountToRedeem,
            getCirculatingSupply()
        );

        designatedToken.safeTransferFrom(msg.sender, avatar, amountToRedeem);

        _exit(tokens, params);
    }

    function getExitAmount(uint256 amount, bytes memory params)
        internal
        pure
        override
        returns (uint256)
    {
        (uint256 amountToRedeem, uint256 _circulatingSupply) = abi.decode(
            params,
            (uint256, uint256)
        );
        return (amountToRedeem * amount) / _circulatingSupply;
    }

    // @dev Change the designated token address variable
    // @param _token Address of new designated token
    // @notice Can only be modified by owner
    function setDesignatedToken(address _token) public onlyOwner {
        designatedToken = ERC20(_token);
    }

    // @dev Change the circulating supply variable
    // @param _circulatingSupply Address of new circulating supply contract
    // @notice Can only be modified by owner
    function setCirculatingSupply(address _circulatingSupply) public onlyOwner {
        circulatingSupply = CirculatingSupplyERC20(_circulatingSupply);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return circulatingSupply.get();
    }
}