//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface ITreasuryEvent{

    /// @dev                        this event occurs when set the calculator address
    /// @param calculatorAddress    calculator address
    event SetCalculator(address calculatorAddress);

    /// @dev                        this event occurs when set the weth address
    /// @param _wethAddress         weth address
    event SetWethAddress(address _wethAddress);

    /// @dev          this event occurs when Treasury's TOS is burned
    /// @param amount burned TOS amount
    event BurnedTos(uint256 amount);

    /// @dev          this event occurs when permission is updated
    /// @param addr   address
    /// @param status status
    /// @param result true or false
    event Permissioned(address addr, uint indexed status, bool result);

    /// @dev          this event occurs mint rate has been updated
    /// @param mrRate mint rate
    /// @param amount TOS amount that is minted
    /// @param isBurn if true burn TOS "amount", else mint TOS "amount”
    event SetMintRate(uint256 mrRate, uint256 amount, bool isBurn);

    /// @dev                      this event occurs when PoolAddressTOSETH is set
    /// @param _poolAddressTOSETH pool address of TOS-ETH pair
    event SetPoolAddressTOSETH(address _poolAddressTOSETH);

    /// @dev                   this event occurs when UniswapV3Factory is set
    /// @param _uniswapFactory address of uniswapFactory
    event SetUniswapV3Factory(address _uniswapFactory);

    /// @dev                        this event occurs when MintRateDenominator is set
    /// @param _mintRateDenominator _mintRateDenominator
    event SetMintRateDenominator(uint256 _mintRateDenominator);

    /// @dev            this event occurs when a new token is added to the backing list
    /// @param _address asset address
    event AddedBackingList(address _address);

    /// @dev            this event occurs when a token is deleted from the backing list
    /// @param _address asset address
    event DeletedBackingList(
        address _address
    );


    /// @dev             this event occurs when Foundation Distribute Info has been added
    /// @param _addr     address list
    /// @param _percents percentage list
    event SetFoundationDistributeInfo(
        address[]  _addr,
        uint256[] _percents
    );

    /// @dev          this event occurs when accmulated TOS from bonding (for the foundation) is transferred to foundation based on the predefined percentage
    /// @param to     the address
    /// @param amount TOS amount distributed to the address
    event DistributedFoundation(
        address to,
        uint256 amount
    );

    /// @dev               this event occurs when request mint and transfer TOS
    /// @param _mintAmount minted TOS amount
    /// @param _payout     Amount of TOS to be earned by the user
    /// @param _distribute if true, distribute a percentage of the remaining amount to the foundation after mint and transfer
    event RequestedMint(
        uint256 _mintAmount,
        uint256 _payout,
        bool _distribute
    );

    /// @dev              this event occurs when request transfer TOS
    /// @param _recipient recipient address
    /// @param _amount    transferred TOS amount
    event RequestedTransfer(
        address _recipient,
        uint256 _amount
    );

}