/*
    Copyright 2021 Babylon Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;
import {LowGasSafeMath} from '../lib/LowGasSafeMath.sol';
import {TimeLockedToken} from './TimeLockedToken.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {IBabController} from '../interfaces/IBabController.sol';

/**
 * @title BABL Token
 * @dev The BABLToken contract is ERC20 using 18 decimals as a standard
 * Is Ownable to transfer ownership to Governor Alpha for Decentralized Governance
 * It overrides the mint and maximum supply to control the timing and maximum cap allowed along the time.
 */

contract BABLToken is TimeLockedToken {
    using LowGasSafeMath for uint256;
    using Address for address;

    /* ============ Events ============ */

    /// @notice An event that emitted when a new mint ocurr
    event MintedNewTokens(address account, uint256 tokensminted);

    /// @notice An event thats emitted when maxSupplyAllowed changes
    event MaxSupplyChanged(uint256 previousMaxValue, uint256 newMaxValue);

    /// @notice An event that emitted when maxSupplyAllowedAfter changes
    event MaxSupplyAllowedAfterChanged(uint256 previousAllowedAfterValue, uint256 newAllowedAfterValue);

    /* ============ Modifiers ============ */

    /* ============ State Variables ============ */

    /// @dev EIP-20 token name for this token
    string private constant NAME = 'Babylon.Finance';

    /// @dev EIP-20 token symbol for this token
    string private constant SYMBOL = 'BABL';

    /// @dev Maximum number of tokens in circulation of 1 million for the first 8 years (using 18 decimals as ERC20 standard)
    uint256 public maxSupplyAllowed = 1_000_000e18; //

    /// @notice The timestamp after which a change on maxSupplyAllowed may occur
    uint256 public maxSupplyAllowedAfter;

    /// @notice Cap on the percentage of maxSupplyAllowed that can be increased per year after maxSupplyAllowedAfter
    uint8 public constant MAX_SUPPLY_CAP = 5;

    /// @notice Cap on the percentage of totalSupply that can be minted at each mint after the initial 1 Million BABL
    uint8 public constant MINT_CAP = 2;

    /// @notice The timestamp after which minting may occur after FIRST_EPOCH_MINT (8 years)
    uint256 public mintingAllowedAfter;

    /// @notice The timestamp of BABL Token deployment
    uint256 public BABLTokenDeploymentTimestamp;

    /// @dev First Epoch Mint where no more than 1 Million BABL can be minted (>= 8 Years)
    uint32 private constant FIRST_EPOCH_MINT = 365 days * 8;

    /// @dev Minimum time between mints after
    uint32 private constant MIN_TIME_BETWEEN_MINTS = 365 days;

    /* ============ Functions ============ */

    /* ============ Constructor ============ */

    /**
     * @notice Construct a new BABL token and gives ownership to sender
     */
    constructor(IBabController newController) TimeLockedToken(NAME, SYMBOL) {
        // Timestamp of contract deployment
        BABLTokenDeploymentTimestamp = block.timestamp;

        // Set-up the minimum time of 8 years to wait until the maxSupplyAllowed can be changed (it will also include a max cap)
        maxSupplyAllowedAfter = block.timestamp.add(FIRST_EPOCH_MINT);

        //Starting with a maxSupplyAllowed of 1 million for the first 8 years
        _mint(msg.sender, 1_000_000e18);

        //Set-up the minimum time of 8 years for additional mints
        mintingAllowedAfter = block.timestamp.add(FIRST_EPOCH_MINT);

        // Set the Babylon Controller
        controller = newController;
    }

    /* ============ External Functions ============ */

    /* ===========  Token related Gov Functions ====== */

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows to mint new tokens
     *
     * @notice Mint new BABL tokens. Initial 1 Million BABL. After 8 years new BABL could be minted by governance decision
     * @dev MINT_CAP The new maximum limit, limited by a 2% cap of totalSupply for each new mint and always limited by maxSupplyAllowed.
     * mintingAllowedAfter Defines the next time allowed for a new mint
     * @param _to The address of the destination account that will receive the new BABL tokens
     * @param _amount The number of tokens to be minted
     * @return Whether or not the mint succeeded
     */
    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        require(totalSupply().add(_amount) <= maxSupplyAllowed, 'BABLToken::mint: max supply exceeded');
        require(
            block.timestamp >= BABLTokenDeploymentTimestamp.add(FIRST_EPOCH_MINT),
            'BABLToken::mint: minting not allowed after the FIRST_EPOCH_MINT has passed >= 8 years'
        );
        require(_amount > 0, 'BABLToken::mint: mint should be higher than zero');
        require(
            block.timestamp >= mintingAllowedAfter,
            'BABLToken::mint: minting not allowed yet because mintingAllowedAfter'
        );
        require(_to != address(0), 'BABLToken::mint: cannot transfer to the zero address');
        require(_to != address(this), 'BABLToken::mint: cannot mint to the address of this contract');

        // set-up the new time where a new (the next) mint can be allowed
        mintingAllowedAfter = block.timestamp.add(MIN_TIME_BETWEEN_MINTS);

        // mint the amount
        uint96 amount = safe96(_amount, 'BABLToken::mint: amount exceeds 96 bits');

        // After FIRST_EPOCH_MINT (8 years) a MINT_CAP applies
        require(
            amount <= totalSupply().mul(MINT_CAP).div(100),
            'BABLToken::mint: exceeded mint cap of 2% of total supply'
        );
        _mint(_to, amount);

        emit MintedNewTokens(_to, amount);

        // move delegates to add voting power to the destination
        _moveDelegates(address(0), delegates[_to], amount);

        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to change maxSupplyAllowed
     *
     * @notice Set-up a greater maxSupplyAllowed value to allow more tokens to be minted
     * @param newMaxSupply The new maximum limit, limited by a maximum of 5% cap per year
     * @param newMaxSupplyAllowedAfter The new waiting period to change the maxSupplyAllowed limited for a minimum of 1 year
     * @return Whether or not the changeMaxSupply succeeded
     */
    function changeMaxSupply(uint256 newMaxSupply, uint256 newMaxSupplyAllowedAfter) external onlyOwner returns (bool) {
        require(
            block.timestamp >= BABLTokenDeploymentTimestamp.add(FIRST_EPOCH_MINT),
            'BABLToken::changeMaxSupply: a change on maxSupplyAllowed not allowed until 8 years after deployment'
        );
        require(
            block.timestamp >= maxSupplyAllowedAfter,
            'BABLToken::changeMaxSupply: a change on maxSupplyAllowed not allowed yet'
        );

        // update the amount
        require(
            newMaxSupply > maxSupplyAllowed,
            'BABLToken::changeMaxSupply: changeMaxSupply should be higher than previous value'
        );
        uint256 limitedNewSupply = maxSupplyAllowed.add(maxSupplyAllowed.mul(MAX_SUPPLY_CAP).div(100));
        require(newMaxSupply <= limitedNewSupply, 'BABLToken::changeMaxSupply: exceeded of allowed 5% cap');
        emit MaxSupplyChanged(maxSupplyAllowed, newMaxSupply);
        maxSupplyAllowed = safe96(newMaxSupply, 'BABLToken::changeMaxSupply: potential max amount exceeds 96 bits');

        // update the new waiting time until a new change could be done >= 1 year since this change
        uint256 futureTime = block.timestamp.add(365 days);
        require(
            newMaxSupplyAllowedAfter >= futureTime,
            'BABLToken::changeMaxSupply: the newMaxSupplyAllowedAfter should be at least 1 year in the future'
        );
        emit MaxSupplyAllowedAfterChanged(maxSupplyAllowedAfter, newMaxSupplyAllowedAfter);
        maxSupplyAllowedAfter = safe96(
            newMaxSupplyAllowedAfter,
            'BABLToken::changeMaxSupply: new newMaxSupplyAllowedAfter exceeds 96 bits'
        );

        return true;
    }

    /**
     * PUBLIC FUNCTION. Get the value of maxSupplyAllowed
     *
     * @return Returns the value of maxSupplyAllowed at the time
     */
    function maxSupply() external view returns (uint96, uint256) {
        uint96 safeMaxSupply =
            safe96(maxSupplyAllowed, 'BABLToken::maxSupplyAllowed: maxSupplyAllowed exceeds 96 bits'); // Overflow check
        return (safeMaxSupply, maxSupplyAllowedAfter);
    }
}