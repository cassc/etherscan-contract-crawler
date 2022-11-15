// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "../libraries/LibTreasury.sol";

interface ITreasury {


    /* ========== onlyPolicyOwner ========== */
    /// @dev            sets permissions to enable policy changes
    /// @param _status  permission number you want to change
    /// @param _address permission the address
    function enable(uint _status,  address _address) external ;

    /// @dev              disables permissions
    /// @param _status    permission number you want to change
    /// @param _toDisable permission the address
    function disable(uint _status, address _toDisable) external;

    /// @dev           sets mintRate and mints or burns TOS amount based on the mintRate
    /// @param _mrRate mintRate is the ratio of setting how many TOS to be minted per 1 ETH
    /// @param amount  mint amount
    /// @param _isBurn if true burn TOS "amount", else mint TOS "amount”
    function setMR(uint256 _mrRate, uint256 amount, bool _isBurn) external;

    /// @dev                       sets the TOS-ETH Pool address
    /// @param _poolAddressTOSETH  TOS-ETH Pool address
    function setPoolAddressTOSETH(address _poolAddressTOSETH) external;

    /// @dev                    sets the uniswapV3Factory address
    /// @param _uniswapFactory  uniswapV3factory address
    function setUniswapV3Factory(address _uniswapFactory) external;

    /// @dev                         sets the mintRateDenominator
    /// @param _mintRateDenominator  mintRateDenominator
    function setMintRateDenominator(uint256 _mintRateDenominator) external;

    /// @dev             adds erc20 token, which is used as a backing asset in Treasury
    /// @param _address  erc20 address
    function addBackingList(address _address) external ;

    /// @dev             deletes erc20 token, which is used as a backing asset in Treasury
    /// @param _address  erc20 address
    function deleteBackingList(address _address) external;

    /// @dev              sets the foundation address and distribution rate
    /// @param _addr      foundation Address
    /// @param _percents  percents
    function setFoundationDistributeInfo(
        address[] memory  _addr,
        uint256[] memory _percents
    ) external ;


    /* ========== onlyOwner ========== */

    /// @dev                    mints TOS. Decides whether to distribute to the foundation or not.
    /// @param _mintAmount      Additional issuance amount of TOS
    /// @param _payout          Amount of TOS to be earned by the user
    /// @param _distribute      If _distribute is true, The amount of foundationTotalPercentage among the issued amounts is allocated to the foundation distribution.
    function requestMint(uint256 _mintAmount, uint256 _payout, bool _distribute) external ;

    /// @dev            addbackingList can be called by bonder
    /// @param _address erc20 Address
    function addBondAsset(
        address _address
    )
        external;

    /* ========== onlyStaker ========== */

    /// @dev              TOS transfer called by staker
    /// @param _recipient recipient address
    /// @param _amount    amount transferred to the recipient
    function requestTransfer(address _recipient, uint256 _amount)  external;

    /* ========== Anyone can execute ========== */

    /* ========== VIEW ========== */

    /// @dev             returns the current mintRate
    /// @return uint256  mintRate
    function getMintRate() external view returns (uint256);

    /// @dev             ETH backing value per 1 TOS
    /// @return uint256  returns ETH backing value per 1 TOS
    function backingRateETHPerTOS() external view returns (uint256);

    /// @dev    checks if registry contains a particular address
    /// @return (bool, uint256)
    function indexInRegistry(address _address, LibTreasury.STATUS _status) external view returns (bool, uint256);


    /// @dev            returns treasury's TOS balance
    /// @return uint256 TOS owned by the treasury (not including the amount owned by the foundation)
    function enableStaking() external view returns (uint256);

    /// @dev            returns assets held by the treasury are converted into ETH
    /// @return uint256 assets held by the treasury are converted into ETH
    function backingReserve() external view returns (uint256) ;

    /// @dev            number of token types backed by treasury
    /// @return uint256 returns the number of token types backed by treasury
    function totalBacking() external view returns (uint256);

    /// @dev                 returns list of erc20 token types counted in backing
    /// @return erc20Address erc20Address
    function allBacking() external view returns (
        address[] memory erc20Address
    );

    /// @dev            returns the total length of mintings
    /// @return uint256 mintings
    function totalMinting() external view returns(uint256) ;

    /// @dev                 returns the foundation distribute minting information of a particular minting index
    /// @param _index        mintings.index
    /// @return mintAddress  mintAddress
    /// @return mintPercents mintPercents
    function viewMintingInfo(uint256 _index)
        external view returns(address mintAddress, uint256 mintPercents);

    /// @dev                 returns the foundation distribute minting information in an array
    /// @return mintAddress  mintAddress
    /// @return mintPercents mintPercents
    function allMinting() external view
        returns (
            address[] memory mintAddress,
            uint256[] memory mintPercents
            );

    /// @dev           checks if an account has a particular permission
    /// @param role    role
    /// @param account address
    /// @return bool   true or false
    function hasPermission(uint role, address account) external view returns (bool);

    /// @dev                  checks if "_checkMintRate" can be set as a new minting rate if "amount" of TOS is minted
    /// @param _checkMintRate changes mintRate
    /// @param amount         mint amount
    /// @return bool          true or false
    function checkTosSolvencyAfterTOSMint (uint256 _checkMintRate, uint256 amount) external view returns (bool);

    /// @dev                  checks if "_checkMintRate" can be set as a new minting rate if "amount" of TOS is burned
    /// @param _checkMintRate changes mintRate
    /// @param amount         burn amount
    /// @return bool          true or false
    function checkTosSolvencyAfterTOSBurn (uint256 _checkMintRate, uint256 amount) external view returns (bool);

    /// @dev          checks if there is enough backing in the treasury to mint more TOS at current minting rate
    /// @param amount mints amount
    /// @return bool  true or false
    function checkTosSolvency (uint256 amount) external view returns (bool);

    /// @dev            returns backing owned by Treasury converted in ETH
    /// @return uint256 ETH Value
    function backingReserveETH() external view returns (uint256);

    /// @dev            returns backing owned by Treasury converted in TOS
    /// @return uint256 TOS Value
    function backingReserveTOS() external view returns (uint256);

    /// @dev            returns the current ETH/TOS price
    /// @return uint256 amount of ETH per 1 TOS
    function getETHPricePerTOS() external view returns (uint256);

    /// @dev            returns the current TOS/ETH price
    /// @return uint256 amount of TOS per 1 ETH
    function getTOSPricePerETH() external view returns (uint256);

    /// @dev           checks if the account has a bonder permission
    /// @param account BonderAddress
    /// @return bool   true or false
    function isBonder(address account) external view returns (bool);

    /// @dev           checks if the account has a staker permission
    /// @param account stakerAddress
    /// @return bool   true or false
    function isStaker(address account) external view returns (bool);
}