// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./util/PausableUpgradeable.sol";
import "./util/SafeERC20Upgradeable.sol";
import "./util/Create2.sol";
import "./proxy/UpgradeableBeacon.sol";
import "./proxy/Create2BeaconProxy.sol";
import "./token/XTokenUpgradeable.sol";
import "./interface/INFTXInventoryStaking.sol";
import "./interface/INFTXVaultFactory.sol";
import "./interface/ITimelockExcludeList.sol";

// Author: 0xKiwi.

// Pausing codes for inventory staking are:
// 10: Deposit

contract NFTXInventoryStaking is
    PausableUpgradeable,
    UpgradeableBeacon,
    INFTXInventoryStaking
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Small locktime to prevent flash deposits.
    uint256 internal constant DEFAULT_LOCKTIME = 2;
    // bytes internal constant beaconCode = type(Create2BeaconProxy).creationCode;
    bytes internal constant beaconCode =
        hex"608060405261002f60017fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d51610451565b6000805160206107cf8339815191521461005957634e487b7160e01b600052600160045260246000fd5b610078336040518060200160405280600081525061007d60201b60201c565b6104a0565b6100908261023860201b6100291760201c565b6100ef5760405162461bcd60e51b815260206004820152602560248201527f426561636f6e50726f78793a20626561636f6e206973206e6f74206120636f6e6044820152641d1c9858dd60da1b60648201526084015b60405180910390fd5b610172826001600160a01b031663da5257166040518163ffffffff1660e01b815260040160206040518083038186803b15801561012b57600080fd5b505afa15801561013f573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061016391906103db565b61023860201b6100291760201c565b6101e45760405162461bcd60e51b815260206004820152603460248201527f426561636f6e50726f78793a20626561636f6e20696d706c656d656e7461746960448201527f6f6e206973206e6f74206120636f6e747261637400000000000000000000000060648201526084016100e6565b6000805160206107cf8339815191528281558151156102335761023161020861023e565b836040518060600160405280602181526020016107ef602191396102cb60201b61002f1760201c565b505b505050565b3b151590565b60006102566000805160206107cf8339815191525490565b6001600160a01b031663da5257166040518163ffffffff1660e01b815260040160206040518083038186803b15801561028e57600080fd5b505afa1580156102a2573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906102c691906103db565b905090565b6060833b61032a5760405162461bcd60e51b815260206004820152602660248201527f416464726573733a2064656c65676174652063616c6c20746f206e6f6e2d636f6044820152651b9d1c9858dd60d21b60648201526084016100e6565b600080856001600160a01b0316856040516103459190610402565b600060405180830381855af49150503d8060008114610380576040519150601f19603f3d011682016040523d82523d6000602084013e610385565b606091505b5090925090506103968282866103a2565b925050505b9392505050565b606083156103b157508161039b565b8251156103c15782518084602001fd5b8160405162461bcd60e51b81526004016100e6919061041e565b6000602082840312156103ec578081fd5b81516001600160a01b038116811461039b578182fd5b60008251610414818460208701610474565b9190910192915050565b602081526000825180602084015261043d816040850160208701610474565b601f01601f19169190910160400192915050565b60008282101561046f57634e487b7160e01b81526011600452602481fd5b500390565b60005b8381101561048f578181015183820152602001610477565b838111156102315750506000910152565b610320806104af6000396000f3fe60806040523661001357610011610017565b005b6100115b61002761002261012e565b6101da565b565b3b151590565b6060833b6100aa5760405162461bcd60e51b815260206004820152602660248201527f416464726573733a2064656c65676174652063616c6c20746f206e6f6e2d636f60448201527f6e7472616374000000000000000000000000000000000000000000000000000060648201526084015b60405180910390fd5b6000808573ffffffffffffffffffffffffffffffffffffffff16856040516100d2919061026b565b600060405180830381855af49150503d806000811461010d576040519150601f19603f3d011682016040523d82523d6000602084013e610112565b606091505b50915091506101228282866101fe565b925050505b9392505050565b60006101587fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d505490565b73ffffffffffffffffffffffffffffffffffffffff1663da5257166040518163ffffffff1660e01b815260040160206040518083038186803b15801561019d57600080fd5b505afa1580156101b1573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906101d59190610237565b905090565b3660008037600080366000845af43d6000803e8080156101f9573d6000f35b3d6000fd5b6060831561020d575081610127565b82511561021d5782518084602001fd5b8160405162461bcd60e51b81526004016100a19190610287565b600060208284031215610248578081fd5b815173ffffffffffffffffffffffffffffffffffffffff81168114610127578182fd5b6000825161027d8184602087016102ba565b9190910192915050565b60208152600082518060208401526102a68160408501602087016102ba565b601f01601f19169190910160400192915050565b60005b838110156102d55781810151838201526020016102bd565b838111156102e4576000848401525b5050505056fea2646970667358221220186f38c9868951054a26d8e78dfc388c93ba31dab42cd0982029e5f5f85fc42164736f6c63430008040033a3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50426561636f6e50726f78793a2066756e6374696f6e2063616c6c206661696c6564";
    // this code is used to determine xToken address while calling `directWithdraw()`
    bytes internal constant duplicateBeaconCode =
        hex"608060405261002f60017fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d51610451565b6000805160206107cf8339815191521461005957634e487b7160e01b600052600160045260246000fd5b610078336040518060200160405280600081525061007d60201b60201c565b6104a0565b6100908261023860201b6100291760201c565b6100ef5760405162461bcd60e51b815260206004820152602560248201527f426561636f6e50726f78793a20626561636f6e206973206e6f74206120636f6e6044820152641d1c9858dd60da1b60648201526084015b60405180910390fd5b610172826001600160a01b031663da5257166040518163ffffffff1660e01b815260040160206040518083038186803b15801561012b57600080fd5b505afa15801561013f573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061016391906103db565b61023860201b6100291760201c565b6101e45760405162461bcd60e51b815260206004820152603460248201527f426561636f6e50726f78793a20626561636f6e20696d706c656d656e7461746960448201527f6f6e206973206e6f74206120636f6e747261637400000000000000000000000060648201526084016100e6565b6000805160206107cf8339815191528281558151156102335761023161020861023e565b836040518060600160405280602181526020016107ef602191396102cb60201b61002f1760201c565b505b505050565b3b151590565b60006102566000805160206107cf8339815191525490565b6001600160a01b031663da5257166040518163ffffffff1660e01b815260040160206040518083038186803b15801561028e57600080fd5b505afa1580156102a2573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906102c691906103db565b905090565b6060833b61032a5760405162461bcd60e51b815260206004820152602660248201527f416464726573733a2064656c65676174652063616c6c20746f206e6f6e2d636f6044820152651b9d1c9858dd60d21b60648201526084016100e6565b600080856001600160a01b0316856040516103459190610402565b600060405180830381855af49150503d8060008114610380576040519150601f19603f3d011682016040523d82523d6000602084013e610385565b606091505b5090925090506103968282866103a2565b925050505b9392505050565b606083156103b157508161039b565b8251156103c15782518084602001fd5b8160405162461bcd60e51b81526004016100e6919061041e565b6000602082840312156103ec578081fd5b81516001600160a01b038116811461039b578182fd5b60008251610414818460208701610474565b9190910192915050565b602081526000825180602084015261043d816040850160208701610474565b601f01601f19169190910160400192915050565b60008282101561046f57634e487b7160e01b81526011600452602481fd5b500390565b60005b8381101561048f578181015183820152602001610477565b838111156102315750506000910152565b610320806104af6000396000f3fe60806040523661001357610011610017565b005b6100115b61002761002261012e565b6101da565b565b3b151590565b6060833b6100aa5760405162461bcd60e51b815260206004820152602660248201527f416464726573733a2064656c65676174652063616c6c20746f206e6f6e2d636f60448201527f6e7472616374000000000000000000000000000000000000000000000000000060648201526084015b60405180910390fd5b6000808573ffffffffffffffffffffffffffffffffffffffff16856040516100d2919061026b565b600060405180830381855af49150503d806000811461010d576040519150601f19603f3d011682016040523d82523d6000602084013e610112565b606091505b50915091506101228282866101fe565b925050505b9392505050565b60006101587fa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d505490565b73ffffffffffffffffffffffffffffffffffffffff1663da5257166040518163ffffffff1660e01b815260040160206040518083038186803b15801561019d57600080fd5b505afa1580156101b1573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906101d59190610237565b905090565b3660008037600080366000845af43d6000803e8080156101f9573d6000f35b3d6000fd5b6060831561020d575081610127565b82511561021d5782518084602001fd5b8160405162461bcd60e51b81526004016100a19190610287565b600060208284031215610248578081fd5b815173ffffffffffffffffffffffffffffffffffffffff81168114610127578182fd5b6000825161027d8184602087016102ba565b9190910192915050565b60208152600082518060208401526102a68160408501602087016102ba565b601f01601f19169190910160400192915050565b60005b838110156102d55781810151838201526020016102bd565b838111156102e4576000848401525b5050505056fea26469706673582212207fa982cc2707bb3e77c4aa1e243fbbca2a5b4869b87391cdd12e6a56d1e36e9164736f6c63430008040033a3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50426561636f6e50726f78793a2066756e6374696f6e2063616c6c206661696c6564";

    INFTXVaultFactory public override nftxVaultFactory;

    uint256 public inventoryLockTimeErc20;
    ITimelockExcludeList public timelockExcludeList;

    event XTokenCreated(uint256 vaultId, address baseToken, address xToken);
    event Deposit(
        uint256 vaultId,
        uint256 baseTokenAmount,
        uint256 xTokenAmount,
        uint256 timelockUntil,
        address sender
    );
    event Withdraw(
        uint256 vaultId,
        uint256 baseTokenAmount,
        uint256 xTokenAmount,
        address sender
    );
    event DirectWithdraw(
        address xToken,
        uint256 baseTokenAmount,
        uint256 xTokenAmount,
        address sender
    );
    event FeesReceived(uint256 vaultId, uint256 amount);

    function __NFTXInventoryStaking_init(address _nftxVaultFactory)
        external
        virtual
        override
        initializer
    {
        __Ownable_init();
        nftxVaultFactory = INFTXVaultFactory(_nftxVaultFactory);
        address xTokenImpl = address(new XTokenUpgradeable());
        __UpgradeableBeacon__init(xTokenImpl);
    }

    modifier onlyAdmin() {
        require(
            msg.sender == owner() ||
                msg.sender == nftxVaultFactory.feeDistributor(),
            "LPStaking: Not authorized"
        );
        _;
    }

    function setTimelockExcludeList(address addr) external onlyOwner {
        timelockExcludeList = ITimelockExcludeList(addr);
    }

    function setInventoryLockTimeErc20(uint256 time) external onlyOwner {
        require(time <= 14 days, "Lock too long");
        inventoryLockTimeErc20 = time;
    }

    function isAddressTimelockExcluded(address addr, uint256 vaultId)
        public
        view
        returns (bool)
    {
        if (address(timelockExcludeList) == address(0)) {
            return false;
        } else {
            return timelockExcludeList.isExcluded(addr, vaultId);
        }
    }

    function deployXTokenForVault(uint256 vaultId) public virtual override {
        address baseToken = nftxVaultFactory.vault(vaultId);
        address deployedXToken = xTokenAddr(address(baseToken));

        if (isContract(deployedXToken)) {
            return;
        }

        address xToken = _deployXToken(baseToken);
        emit XTokenCreated(vaultId, baseToken, xToken);
    }

    function receiveRewards(uint256 vaultId, uint256 amount)
        external
        virtual
        override
        onlyAdmin
        returns (bool)
    {
        address baseToken = nftxVaultFactory.vault(vaultId);
        address deployedXToken = xTokenAddr(address(baseToken));

        // Don't distribute rewards unless there are people to distribute to.
        // Also added here if the distribution token is not deployed, just forfeit rewards for now.
        if (
            !isContract(deployedXToken) ||
            XTokenUpgradeable(deployedXToken).totalSupply() == 0
        ) {
            return false;
        }
        // We "pull" to the dividend tokens so the fee distributor only needs to approve this contract.
        IERC20Upgradeable(baseToken).safeTransferFrom(
            msg.sender,
            deployedXToken,
            amount
        );
        emit FeesReceived(vaultId, amount);
        return true;
    }

    // Enter staking. Staking, get minted shares and
    // locks base tokens and mints xTokens.
    function deposit(uint256 vaultId, uint256 _amount)
        external
        virtual
        override
    {
        onlyOwnerIfPaused(10);

        uint256 timelockTime = isAddressTimelockExcluded(msg.sender, vaultId)
            ? 0
            : inventoryLockTimeErc20;

        (
            IERC20Upgradeable baseToken,
            XTokenUpgradeable xToken,
            uint256 xTokensMinted
        ) = _timelockMintFor(vaultId, msg.sender, _amount, timelockTime);
        // Lock the base token in the xtoken contract
        baseToken.safeTransferFrom(msg.sender, address(xToken), _amount);
        emit Deposit(vaultId, _amount, xTokensMinted, timelockTime, msg.sender);
    }

    function timelockMintFor(
        uint256 vaultId,
        uint256 amount,
        address to,
        uint256 timelockLength
    ) external virtual override returns (uint256) {
        onlyOwnerIfPaused(10);
        require(nftxVaultFactory.zapContracts(msg.sender), "Not staking zap");
        require(
            nftxVaultFactory.excludedFromFees(msg.sender),
            "Not fee excluded"
        );

        (, , uint256 xTokensMinted) = _timelockMintFor(
            vaultId,
            to,
            amount,
            timelockLength
        );
        emit Deposit(vaultId, amount, xTokensMinted, timelockLength, to);
        return xTokensMinted;
    }

    // Leave the bar. Claim back your tokens.
    // Unlocks the staked + gained tokens and burns xTokens.
    function withdraw(uint256 vaultId, uint256 _share)
        external
        virtual
        override
    {
        IERC20Upgradeable baseToken = IERC20Upgradeable(
            nftxVaultFactory.vault(vaultId)
        );
        XTokenUpgradeable xToken = XTokenUpgradeable(
            xTokenAddr(address(baseToken))
        );

        uint256 baseTokensRedeemed = xToken.burnXTokens(msg.sender, _share);
        emit Withdraw(vaultId, baseTokensRedeemed, _share, msg.sender);
    }

    function directWithdraw(uint256 vaultId, uint256 _share) external {
        IERC20Upgradeable baseToken = IERC20Upgradeable(
            nftxVaultFactory.vault(vaultId)
        );
        bytes32 salt = keccak256(abi.encodePacked(baseToken));
        address xToken = Create2.computeAddress(
            salt,
            keccak256(duplicateBeaconCode)
        );
        uint256 baseTokensRedeemed = XTokenUpgradeable(xToken).burnXTokens(
            msg.sender,
            _share
        );

        emit DirectWithdraw(xToken, baseTokensRedeemed, _share, msg.sender);
    }

    function xTokenShareValue(uint256 vaultId)
        external
        view
        virtual
        override
        returns (uint256)
    {
        IERC20Upgradeable baseToken = IERC20Upgradeable(
            nftxVaultFactory.vault(vaultId)
        );
        XTokenUpgradeable xToken = XTokenUpgradeable(
            xTokenAddr(address(baseToken))
        );
        require(address(xToken) != address(0), "XToken not deployed");

        uint256 multiplier = 10**18;
        return
            xToken.totalSupply() > 0
                ? (multiplier * baseToken.balanceOf(address(xToken))) /
                    xToken.totalSupply()
                : multiplier;
    }

    function timelockUntil(uint256 vaultId, address who)
        external
        view
        returns (uint256)
    {
        XTokenUpgradeable xToken = XTokenUpgradeable(vaultXToken(vaultId));
        return xToken.timelockUntil(who);
    }

    function balanceOf(uint256 vaultId, address who)
        external
        view
        returns (uint256)
    {
        XTokenUpgradeable xToken = XTokenUpgradeable(vaultXToken(vaultId));
        return xToken.balanceOf(who);
    }

    // Note: this function does not guarantee the token is deployed, we leave that check to elsewhere to save gas.
    function xTokenAddr(address baseToken)
        public
        view
        virtual
        override
        returns (address)
    {
        bytes32 salt = keccak256(abi.encodePacked(baseToken));
        address tokenAddr = Create2.computeAddress(salt, keccak256(beaconCode));
        return tokenAddr;
    }

    function vaultXToken(uint256 vaultId)
        public
        view
        virtual
        override
        returns (address)
    {
        address baseToken = nftxVaultFactory.vault(vaultId);
        address xToken = xTokenAddr(baseToken);
        require(isContract(xToken), "XToken not deployed");
        return xToken;
    }

    function _timelockMintFor(
        uint256 vaultId,
        address account,
        uint256 _amount,
        uint256 timelockLength
    )
        internal
        returns (
            IERC20Upgradeable,
            XTokenUpgradeable,
            uint256
        )
    {
        deployXTokenForVault(vaultId);
        IERC20Upgradeable baseToken = IERC20Upgradeable(
            nftxVaultFactory.vault(vaultId)
        );
        XTokenUpgradeable xToken = XTokenUpgradeable(
            (xTokenAddr(address(baseToken)))
        );

        uint256 xTokensMinted = xToken.mintXTokens(
            account,
            _amount,
            timelockLength
        );
        return (baseToken, xToken, xTokensMinted);
    }

    function _deployXToken(address baseToken) internal returns (address) {
        string memory symbol = IERC20Metadata(baseToken).symbol();
        symbol = string(abi.encodePacked("x", symbol));
        bytes32 salt = keccak256(abi.encodePacked(baseToken));
        address deployedXToken = Create2.deploy(0, salt, beaconCode);
        XTokenUpgradeable(deployedXToken).__XToken_init(
            baseToken,
            symbol,
            symbol
        );
        return deployedXToken;
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size != 0;
    }
}