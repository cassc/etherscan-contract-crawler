// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "solady/src/auth/Ownable.sol";
import "openzeppelin/interfaces/IERC20.sol";
import "openzeppelin/interfaces/IERC721.sol";
import "openzeppelin/proxy/utils/Initializable.sol";
import "liquidity-helper/UniswapV2LiquidityHelper.sol";

interface INFTXFactory {
    function vaultsForAsset(address asset) external view returns (address[] memory);
}

interface INFTXVault {
    function vaultId() external view returns (uint256);
}

interface INFTXLPStaking {
    function deposit(uint256 vaultId, uint256 amount) external;
    function claimRewards(uint256 vaultId) external;
}

interface INFTXStakingZap {
    function addLiquidity721(uint256 vaultId, uint256[] calldata ids, uint256 minWethIn, uint256 wethIn)
        external
        returns (uint256);
}

/**
 * @title AlignmentVault
 * @notice This allows anything to send ETH to a vault for the purpose of permanently deepening the floor liquidity of a target NFT collection.
 * While the liquidity is locked forever, the yield can be claimed indefinitely.
 * @dev You must initialize this contract once deployed! There is a factory for this, use it!
 * @author Zodomo.eth (X: @0xZodomo, Telegram: @zodomo, GitHub: Zodomo, Email: [email protected])
 */
contract AlignmentVault is Ownable, Initializable {
    error InsufficientFunds();
    error InvalidVaultId();
    error AlignedAsset();
    error NoNFTXVault();
    error UnwantedNFT();

    IWETH internal constant _WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address internal constant _SUSHI_V2_FACTORY = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
    IUniswapV2Router02 internal constant _SUSHI_V2_ROUTER =
        IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    INFTXFactory internal constant _NFTX_VAULT_FACTORY = INFTXFactory(0xBE86f647b167567525cCAAfcd6f881F1Ee558216);
    INFTXLPStaking internal constant _NFTX_LIQUIDITY_STAKING =
        INFTXLPStaking(0x688c3E4658B5367da06fd629E41879beaB538E37);
    INFTXStakingZap internal constant _NFTX_STAKING_ZAP = INFTXStakingZap(0xdC774D5260ec66e5DD4627E1DD800Eff3911345C);

    UniswapV2LiquidityHelper internal _liqHelper; // Liquidity helper used to deepen NFTX SLP with any amount of tokens
    IERC721 public erc721; // ERC721 token
    IERC20 public nftxInventory; // NFTX NFT token
    IERC20 public nftxLiquidity; // NFTX NFTWETH token
    uint256 public vaultId; // NFTX vault Id
    uint256[] public nftsHeld; // Inventory of aligned erc721 NFTs stored in contract

    constructor() payable {}

    /**
    * @notice Initializes all contract variables and NFTX integration
    * @param _erc721 Address of the target ERC721 contract
    * @param _owner Address of the owner to be set for this contract
    * @param _vaultId Identifier for the NFTX vault. If set to 0, the default (initial) vault will be used.
    */
    function initialize(address _erc721, address _owner, uint256 _vaultId) external payable virtual initializer {
        // Initialize contract ownership
        _initializeOwner(_owner);
        // Set target NFT collection for alignment
        erc721 = IERC721(_erc721);
        // Approve sending any NFT tokenId to NFTX Staking Zap contract
        erc721.setApprovalForAll(address(_NFTX_STAKING_ZAP), true);
        // Max approve WETH to NFTX LP Staking contract
        IERC20(address(_WETH)).approve(address(_NFTX_STAKING_ZAP), type(uint256).max);
        // Derive vaultId if necessary
        // Loop index is set to max value in order to determine if a match was found
        uint256 index = type(uint256).max;
        // If no vaultId is specified, use default (initial) vault
        if (_vaultId == 0) {
            index = 0;
        } else {
            // Retrieve all vaults
            address[] memory vaults = _NFTX_VAULT_FACTORY.vaultsForAsset(_erc721);
            // Revert if no vaults are returned
            if (vaults.length == 0) revert NoNFTXVault();
            // Search for vaultId
            for (uint256 i; i < vaults.length;) {
                if (INFTXVault(vaults[i]).vaultId() == _vaultId) {
                    index = i;
                    vaultId = _vaultId;
                    break;
                }
                unchecked {
                    ++i;
                }
            }
            // If vaultId wasn't found, revert
            if (index == type(uint256).max) revert InvalidVaultId();
        }
        // Derive nftxInventory token contract and vaultId if necessary
        address _nftxInventory = _NFTX_VAULT_FACTORY.vaultsForAsset(_erc721)[index];
        if (_vaultId == 0) vaultId = uint64(INFTXVault(_nftxInventory).vaultId());
        nftxInventory = IERC20(_nftxInventory);
        // Derive nftxLiquidity LP contract
        nftxLiquidity = IERC20(UniswapV2Library.pairFor(_SUSHI_V2_FACTORY, address(_WETH), _nftxInventory));
        // Approve sending nftxLiquidity to NFTX LP Staking contract
        nftxLiquidity.approve(address(_NFTX_LIQUIDITY_STAKING), type(uint256).max);
        // Setup liquidity helper
        _liqHelper = new UniswapV2LiquidityHelper(_SUSHI_V2_FACTORY, address(_SUSHI_V2_ROUTER), address(_WETH));
        // Approve tokens to liquidity helper
        IERC20(address(_WETH)).approve(address(_liqHelper), type(uint256).max);
        nftxInventory.approve(address(_liqHelper), type(uint256).max);
    }

    /**
    * @notice Disables the ability to call initialization functions again, recommended post-initialization
    */
    function disableInitializers() external payable virtual {
        _disableInitializers();
    }

    /**
    * @notice The ability to renounce is overridden as it would break the vault. A privileged caller is required.
    */
    function renounceOwnership() public payable virtual override {}

    /**
    * @notice Estimate the floor price of the NFT in terms of WETH based on NFTX SLP reserves
    * @return spotPrice The estimated price of the NFT token in WETH
    */
    function _estimateFloor() internal view virtual returns (uint256 spotPrice) {
        // Retrieve SLP reserves to calculate price of NFT token in WETH
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(address(nftxLiquidity)).getReserves();
        // Calculate value of NFT spot in WETH using SLP reserves values
        // Reverse reserve values if token1 isn't WETH
        if (IUniswapV2Pair(address(nftxLiquidity)).token1() != address(_WETH)) {
            spotPrice = ((10 ** 18 * uint256(reserve0)) / uint256(reserve1));
        } else {
            spotPrice = ((10 ** 18 * uint256(reserve1)) / uint256(reserve0));
        }
        return (spotPrice);
    }

    /**
    * @notice Wrap all ETH, if any, before function execution
    */
    function _wrapEth() internal virtual {
        // Wrap all ETH, if any
        uint256 balance = address(this).balance;
        if (balance > 0) _WETH.deposit{value: balance}();
    }

    /**
    * @notice Stake all LP tokens, if any
    */
    function _stakeLiquidity() internal virtual {
        uint256 liquidity = nftxLiquidity.balanceOf(address(this));
        if (liquidity > 0) _NFTX_LIQUIDITY_STAKING.deposit(vaultId, liquidity);
    }

    /**
    * @notice Add aligned NFTs to NFTX vault by pairing them with their floor price in ETH
    * @dev This will revert if the contract doesn't hold the NFT. This doesn't require checkInventory().
    * @param _tokenIds Array of specific NFTs to try and add to the vault
    */
    function alignNfts(uint256[] memory _tokenIds) external payable virtual onlyOwner {
        // Revert if empty _tokenIds array is passed
        if (_tokenIds.length == 0) revert();
        // Wrap all ETH, if any
        _wrapEth();
        // Retrieve total WETH balance
        uint256 balance = IERC20(address(_WETH)).balanceOf(address(this));
        // Retrieve NFTX LP price for one NFT
        uint256 floorPrice = _estimateFloor();
        // Add 1 to floorPrice in order to resolve liquidity rounding issue
        uint256 afford = balance / (floorPrice + 1);
        // Revert if we cannot afford this amount of NFTs
        if (afford < _tokenIds.length) revert InsufficientFunds();
        // Calculate exact ETH to add to LP with NFTs
        uint256 requiredEth = _tokenIds.length * (floorPrice + 1);
        // Stake NFTs and ETH, approvals were given in initializeVault()
        _NFTX_STAKING_ZAP.addLiquidity721(vaultId, _tokenIds, 1, requiredEth);
        // Stake any held liquidity tokens
        _stakeLiquidity();
        // Purge tokenIds if they exist in nftsHeld inventory
        for (uint256 i; i < _tokenIds.length;) {
            // Cache nftsHeld for each aligned tokenId as its length will change upon each pop
            uint256[] memory inventory = nftsHeld;
            for (uint256 j; j < inventory.length;) {
                if (inventory[j] == _tokenIds[i]) {
                    nftsHeld[j] = nftsHeld[inventory.length - 1];
                    nftsHeld.pop();
                }
                unchecked { ++j; }
            }
            unchecked { ++i; }
        }
    }

    /**
    * @notice Add specific amount of ETH/WETH and all fractionalized NFT tokens to NFTX vault
    * @dev Any ETH (msg.value or address(this).balance) will be wrapped to WETH before processing
    * @param _amount is the total amount of WETH to add
    */
    function alignTokens(uint256 _amount) external payable virtual onlyOwner {
        // Wrap all ETH, if any
        _wrapEth();
        // Retrieve total WETH balance
        uint256 balance = IERC20(address(_WETH)).balanceOf(address(this));
        // Revert if _amount is over balance
        if (_amount > balance) revert InsufficientFunds();
        // Cache nftxInventory to prevent a double SLOAD
        uint256 nftxInvBal = nftxInventory.balanceOf(address(this));
        // Process rebalancing remaining ETH and inventory tokens (if any) to add to LP
        if (_amount > 0 || nftxInvBal > 0) {
            _liqHelper.swapAndAddLiquidityTokenAndToken(
                address(_WETH), address(nftxInventory), uint112(_amount), uint112(nftxInvBal), 1, address(this)
            );
        }
        // Stake any held liquidity tokens
        _stakeLiquidity();
    }

    /**
    * @notice Aligns max liquidity by depositing NFTs and ETH into the NFTX vault and staking them
    * This will add as many NFTs as it can afford, before staking the ETH remainder
    * Confirm vault has enough ETH for NFTs held before aligning max liquidity
    */
    function alignMaxLiquidity() external payable virtual onlyOwner {
        // Cache vaultId to save gas
        uint256 _vaultId = vaultId;
        // Wrap all ETH, if any
        _wrapEth();
        // Retrieve total WETH balance
        uint256 balance = IERC20(address(_WETH)).balanceOf(address(this));

        // Retrieve NFTs held
        uint256[] memory inventory = nftsHeld;
        uint256 length = inventory.length;
        // Process adding liquidity using as many NFTs as the ETH balance allows
        if (length > 0) {
            // Retrieve NFTX LP price for 1 full inventory token
            uint256 floorPrice = _estimateFloor();
            // Determine how many NFTs we can afford to add to LP
            // Add 1 to floorPrice in order to resolve liquidity rounding issue
            uint256 afford = balance / (floorPrice + 1);
            uint256 addQty;
            // If we can afford to add more than we have, add what we have, otherwise add what we can afford
            (afford >= length) ? addQty = length : addQty = afford;
            // Add NFTs to LP if we can afford to
            if (addQty > 0) {
                // Calculate exact ETH to add to LP with NFTs
                uint256 requiredEth = addQty * (floorPrice + 1);
                // Iterate through inventory for as many NFTs as we can afford to add
                uint256[] memory tokenIds = new uint256[](addQty);
                for (uint256 i; i < addQty;) {
                    tokenIds[i] = inventory[length - addQty + i];
                    nftsHeld.pop();
                    unchecked {
                        ++i;
                    }
                }
                // Stake NFTs and ETH, approvals were given in initializeVault()
                _NFTX_STAKING_ZAP.addLiquidity721(_vaultId, tokenIds, 1, requiredEth);
                // Update cached balance after adding NFTs to vault
                balance = IERC20(address(_WETH)).balanceOf(address(this));
            }
        }

        // Cache nftxInventory to prevent a double SLOAD
        uint256 nftxInvBal = nftxInventory.balanceOf(address(this));
        // Process rebalancing remaining ETH and inventory tokens (if any) to add to LP
        if (balance > 0 || nftxInvBal > 0) {
            _liqHelper.swapAndAddLiquidityTokenAndToken(
                address(_WETH), address(nftxInventory), uint112(balance), uint112(nftxInvBal), 1, address(this)
            );
        }

        // Stake any held liquidity tokens
        _stakeLiquidity();
    }

    /**
    * @notice Claims yield generated by the staked NFTWETH SLP. Yield can be compounded or split with a recipient.
    * @param _recipient Address to receive 50% of the yield. If address(0), the yield will be compounded.
    */
    function claimYield(address _recipient) external payable virtual onlyOwner {
        // Cache vaultId to save gas
        uint256 _vaultId = vaultId;
        // Claim SLP rewards
        _NFTX_LIQUIDITY_STAKING.claimRewards(_vaultId);
        // Determine yield amount
        uint256 yield = nftxInventory.balanceOf(address(this));
        // If no yield, end execution to save gas
        if (yield == 0) return;
        // If recipient is provided, send them 50%
        if (_recipient != address(0)) {
            uint256 amount;
            unchecked {
                amount = yield / 2;
                yield -= amount;
            }
            nftxInventory.transfer(_recipient, amount);
        }
        // Send all remaining yield to LP
        _liqHelper.swapAndAddLiquidityTokenAndToken(
            address(_WETH), address(nftxInventory), 0, uint112(yield), 1, address(this)
        );
        // Stake all liquidity tokens
        _stakeLiquidity();
    }

    /**
    * @notice Checks the contract's inventory to recognize any new NFTs that were transferred unsafely
    * @param _tokenIds Array of tokenIds to check against the contract's inventory
    */
    function checkInventory(uint256[] memory _tokenIds) external payable virtual {
        // Cache nftsHeld to reduce SLOADs
        uint256[] memory inventory = nftsHeld;
        // Iterate through passed array
        for (uint256 i; i < _tokenIds.length;) {
            // Try check for ownership used in case token has been burned
            try erc721.ownerOf(_tokenIds[i]) {
                // If this address is the owner, see if it is in nftsHeld cached array
                if (erc721.ownerOf(_tokenIds[i]) == address(this)) {
                    bool noticed;
                    for (uint256 j; j < inventory.length;) {
                        // If NFT is found, end loop and iterate to next tokenId
                        if (inventory[j] == _tokenIds[i]) {
                            noticed = true;
                            break;
                        }
                        unchecked {
                            ++j;
                        }
                    }
                    // If tokenId wasn't in stored array, add it
                    if (!noticed) nftsHeld.push(_tokenIds[i]);
                }
            } catch {}
            unchecked {
                ++i;
            }
        }
    }

    /**
    * @notice Retrieve known NFT inventory to check if contract is aware of holdings
    */
    function getInventory() external view virtual returns (uint256[] memory) {
        return nftsHeld;
    }

    /**
    * @notice Allows the owner to rescue ERC20 tokens or ETH from vault and/or liquidity helper.
    * For aligned assets (like ETH, WETH, nftxInventory, nftxLiquidity), the function will rescue 
    * the assets to the vault itself and return 0. For any other tokens, it will rescue from both 
    * the liquidity helper and the vault, and then send the total balance to a specified address.
    * 
    * @param _token The address of the ERC20 token to rescue. Use address(0) for ETH.
    * @param _to The recipient address to send the rescued tokens to.
    * @return amount Returns the amount of tokens sent to the recipient. Returns 0 for aligned assets.
    */
    function rescueERC20(address _token, address _to) external payable virtual onlyOwner returns (uint256 amount) {
        // If address(0), rescue ETH from liq helper to vault
        if (_token == address(0)) {
            _liqHelper.emergencyWithdrawEther();
            uint256 balance = address(this).balance;
            if (balance > 0) _WETH.deposit{value: balance}();
            return (0);
        }
        // If WETH, nftxInventory, or nftxLiquidity, rescue from liq helper to vault
        else if (_token == address(_WETH) || _token == address(nftxInventory) || _token == address(nftxLiquidity)) {
            _liqHelper.emergencyWithdrawErc20(_token);
            return (0);
        }
        // If any other token, rescue from liq helper and/or vault and send to recipient
        else {
            // Retrieve tokens from liq helper, if any
            if (IERC20(_token).balanceOf(address(_liqHelper)) > 0) {
                _liqHelper.emergencyWithdrawErc20(_token);
            }
            // Check updated balance
            uint256 balance = IERC20(_token).balanceOf(address(this));
            // Send entire balance to recipient
            IERC20(_token).transfer(_to, balance);
            return (balance);
        }
    }
    
    /**
    * @notice Allows the owner to rescue non-aligned ERC721 tokens. If the ERC721 token is from the 
    * aligned collection, the transaction is reverted.
    *
    * @param _token The address of the ERC721 token contract.
    * @param _to The recipient address to send the rescued NFT to.
    * @param _tokenId The ID of the NFT to be rescued.
    */
    function rescueERC721(address _token, address _to, uint256 _tokenId) external payable virtual onlyOwner {
        // If _address is for the aligned collection, revert
        if (address(erc721) == _token) revert AlignedAsset();
        // Otherwise, attempt to send to recipient
        else IERC721(_token).transferFrom(address(this), _to, _tokenId);
    }

    /**
    * @notice Fallback function that converts any received ETH to WETH.
    */
    receive() external payable virtual {
        _WETH.deposit{value: msg.value}();
    }
    
    /**
    * @notice Handles the logic when an ERC721 NFT is sent to this contract. Logs only aligned NFTs, 
    * and reverts if any other NFTs are sent.
    *
    * @param _tokenId The ID of the received NFT.
    * @return magicBytes Returns a bytes4 magic value if the NFT transfer is accepted.
    */
    function onERC721Received(address, address, uint256 _tokenId, bytes calldata) external virtual returns (bytes4 magicBytes) {
        if (msg.sender == address(erc721)) nftsHeld.push(_tokenId);
        else revert UnwantedNFT();
        return AlignmentVault.onERC721Received.selector;
    }
}