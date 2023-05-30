// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import './interfaces/IVaultFactory.sol';
import './Vault.sol';

contract VaultFactory is IVaultFactory, Moderable, ReentrancyGuard {
    address[] public vaults;
    mapping(address => bool) public vaultExists;
    mapping(address => address) public tokenToVault;
    address public flashLoanProviderAddress;
    bool public isInitialized = false;
    ERC20 public tokenToPayInFee;
    uint256 public feeToPublishVault;
    address public treasuryAddress = 0xA49174859aA91E139b586F08BbB69BceE847d8a7;

    /**
     * @dev Only if Vault Factory is not initialized.
     **/
    modifier onlyNotInitialized {
        require(isInitialized == false, 'ONLY_NOT_INITIALIZED');
        _;
    }

    /**
     * @dev Only if Vault Factory is initialized.
     **/
    modifier onlyInitialized {
        require(isInitialized, 'ONLY_INITIALIZED');
        _;
    }

    /**
     * @dev Change treasury address.
     * @param _treasuryAddress address of treasury where part of flash loan fee is sent.
     */
    function setTreasuryAddress(address _treasuryAddress) external onlyModerator {
        treasuryAddress = _treasuryAddress;
        emit VaultFactorySetTreasuryAddress(treasuryAddress);
    }

    /**
     * @dev Initialize VaultFactory
     * @param _flashLoanProviderAddress contract to use for getting Flash Loan.
     * @param _tokenToPayInFee address of token used for paying fee of listing Vault.
     */
    function initialize(address _flashLoanProviderAddress, address _tokenToPayInFee)
        external
        onlyModerator
        onlyNotInitialized
    {
        tokenToPayInFee = ERC20(_tokenToPayInFee);
        feeToPublishVault = 100000 * 10**tokenToPayInFee.decimals();
        flashLoanProviderAddress = _flashLoanProviderAddress;
        isInitialized = true;
    }

    /**
     * @dev Set/Change fee for publishing your Vault.
     * @param _feeToPublishVault amount set to be paid when creating a Vault.
     */
    function setFeeToPublishVault(uint256 _feeToPublishVault) external onlyModerator {
        feeToPublishVault = _feeToPublishVault;
        emit VaultFactorySetFeeToPublishVault(feeToPublishVault);
    }

    /**
     * @dev Create vault factory method.
     * @param stakedToken address of staked token in a vault
     * @param maxCapacity value for Vault.
     */
    function createVault(address stakedToken, uint256 maxCapacity)
        external
        onlyModerator
        onlyInitialized
    {
        _createVault(stakedToken, maxCapacity);
    }

    /**
     * @dev Overloaded createVault method used for externally be called by anyone that pays fee.
     * @param stakedToken used as currency for depositing into Vault.
     **/
    function createVault(address stakedToken) external onlyInitialized nonReentrant {
        IERC20 token = IERC20(stakedToken);
        require(
            tokenToPayInFee.transferFrom(msg.sender, address(this), feeToPublishVault),
            'FEE_TRANSFER_FAILED'
        );
        require(token.totalSupply() > 0, 'TOTAL_SUPPLY_LESS_THAN_ZERO');
        _createVault(stakedToken, token.totalSupply() / 2);
    }

    /**
     * @dev Create vault internal factory method.
     * @param stakedToken address of staked token in a vault
     * @param maxCapacity value for Vault.
     */
    function _createVault(address stakedToken, uint256 maxCapacity) internal {
        require(tokenToVault[stakedToken] == address(0), 'VAULT_ALREADY_EXISTS');
        bytes32 salt = keccak256(abi.encodePacked(stakedToken));

        Vault vault = new Vault{salt: salt}(ERC20(stakedToken));

        vaults.push(address(vault));
        vaultExists[address(vault)] = true;
        tokenToVault[stakedToken] = address(vault);

        vault.initialize(treasuryAddress, flashLoanProviderAddress, maxCapacity);

        vault.transferModeratorship(moderator()); //Moderator of VaultFactory is moderator of Vault. Otherwise moderator would be the VaultFactory

        emit VaultCreated(address(vault));
    }

    /**
     * @dev Withdraw funds payed as tax for Vault listing.
     **/
    function withdraw() external onlyModerator {
        require(
            tokenToPayInFee.transfer(msg.sender, tokenToPayInFee.balanceOf(address(this))),
            'WITHDRAW_TRANSFER_ERROR'
        );
    }

    /**
     * @dev Count how many vaults have been created so far.
     * @return Number of vaults created.
     */
    function countVaults() external view returns (uint256) {
        return vaults.length;
    }

    /**
     * @dev Precompute address of vault.
     * @param stakedToken address for a specific vault liquidity token.
     * @return Address a vault will have.
     */
    function precomputeAddress(address stakedToken) external view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(stakedToken));
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                address(this),
                                salt,
                                keccak256(
                                    abi.encodePacked(
                                        type(Vault).creationCode,
                                        abi.encode(ERC20(stakedToken))
                                    )
                                )
                            )
                        )
                    )
                )
            );
    }
}