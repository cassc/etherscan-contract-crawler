//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "./AllowList.sol";
import "./TokenSale.sol";
import "./interfaces/IENS.sol";
import "./interfaces/IENSResolver.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IFactorySafeHelper.sol";

contract AlbumFactory {
    event AlbumCreated(
        string name,
        address sale,
        address safe,
        address realityModule,
        address token
    );

    error NotAllowedError();
    error MinimumTotalTokensNotMetError(uint256 minimum);
    error NotEnoughTokensLeftForRakeError();
    error ENSSubNameUnavailableError();
    error InvalidDistributeParameters();

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint256 public constant SZNS_DAO_RAKE_DIVISOR = 100;

    AllowList public immutable ALLOW_LIST;
    IFactorySafeHelper public immutable FACTORY_SAFE_HELPER;
    IENS public immutable ENS;
    address public immutable ENS_PUBLIC_RESOLVER_ADDRESS;
    bytes32 public immutable BASE_ENS_NODE;
    address public immutable SZNS_DAO;
    address public immutable TOKEN_SALE_MASTER_COPY;

    struct TokenParams {
        string symbol;
        uint256 totalTokens;
    }

    struct ERC721Grouping {
        IERC721 erc721;
        uint256[] ids;
    }

    constructor(
        address allowListAddress,
        address factorySafeHelperAddress,
        address ensAddress,
        address ensPublicResolverAddress,
        bytes32 baseEnsNode,
        address sznsDao
    ) {
        ALLOW_LIST = AllowList(allowListAddress);
        FACTORY_SAFE_HELPER = IFactorySafeHelper(factorySafeHelperAddress);
        ENS = IENS(ensAddress);
        BASE_ENS_NODE = baseEnsNode;
        ENS_PUBLIC_RESOLVER_ADDRESS = ensPublicResolverAddress;
        SZNS_DAO = sznsDao;
        TOKEN_SALE_MASTER_COPY = address(
            new TokenSale(address(1), address(1), TokenSale.Params(0, 0, 1, 0))
        );
    }

    function createAlbum(
        string memory name,
        TokenParams memory tokenParams,
        TokenSale.Params memory tokenSaleParams,
        // AlbumFactory contract has to be approved to transfer all of these NFTs!
        ERC721Grouping[] calldata erc721Groupings,
        bytes[] calldata ensResolverData
    ) external {
        if (!ALLOW_LIST.getIsAllowed(msg.sender)) {
            revert NotAllowedError();
        }
        if (tokenParams.totalTokens < 100 ether) {
            revert MinimumTotalTokensNotMetError(100);
        }
        if (
            tokenParams.totalTokens - tokenSaleParams.numTokens <
            tokenParams.totalTokens / SZNS_DAO_RAKE_DIVISOR
        ) {
            revert NotEnoughTokensLeftForRakeError();
        }

        address safe;
        address realityModule;
        bytes32 ensSubNode;
        {
            bytes32 nameHash = keccak256(abi.encodePacked(name));
            ensSubNode = keccak256(abi.encodePacked(BASE_ENS_NODE, nameHash));
            if (ENS.owner(ensSubNode) != address(0)) {
                revert ENSSubNameUnavailableError();
            }
            (safe, realityModule) = FACTORY_SAFE_HELPER.createAndSetupSafe(
                ensSubNode
            );
            ENS.setSubnodeOwner(BASE_ENS_NODE, nameHash, address(this));
            ENS.setResolver(ensSubNode, ENS_PUBLIC_RESOLVER_ADDRESS);
            IENSResolver(ENS_PUBLIC_RESOLVER_ADDRESS).multicall(
                ensResolverData
            );
            ENS.setOwner(ensSubNode, safe);
        }
        for (uint256 i = 0; i < erc721Groupings.length; i++) {
            for (uint256 j = 0; j < erc721Groupings[i].ids.length; ++j) {
                erc721Groupings[i].erc721.safeTransferFrom(
                    msg.sender,
                    safe,
                    erc721Groupings[i].ids[j]
                );
            }
        }
        address token = createAndSetupToken(name, tokenParams.symbol, safe);
        address sale;
        // if there are no tokens for the sale, then don't bother deploying the token sale contract
        if (tokenSaleParams.numTokens > 0) {
            sale = createAndSetupTokenSale(token, tokenSaleParams, ensSubNode);
        } else {
            // emit zero address is no sale contract
            sale = address(0);
        }
        distributeAlbumTokens(
            token,
            tokenParams.totalTokens,
            tokenSaleParams.numTokens,
            sale
        );
        emit AlbumCreated(name, sale, safe, realityModule, token);
    }

    function createAndSetupToken(
        string memory name,
        string memory symbol,
        address safeAddress
    ) internal returns (address) {
        ERC20PresetMinterPauser token = new ERC20PresetMinterPauser{salt: ""}(
            name,
            symbol
        );
        token.grantRole(DEFAULT_ADMIN_ROLE, safeAddress);
        token.grantRole(MINTER_ROLE, safeAddress);
        token.grantRole(PAUSER_ROLE, safeAddress);
        return address(token);
    }

    function createAndSetupTokenSale(
        address tokenAddress,
        TokenSale.Params memory tokenSaleParams,
        bytes32 salt
    ) internal returns (address created) {
        created = Clones.cloneDeterministic(TOKEN_SALE_MASTER_COPY, salt);
        TokenSale(created).initialize(
            msg.sender,
            tokenAddress,
            tokenSaleParams
        );
    }

    function distributeAlbumTokens(
        address _token,
        uint256 totalTokens,
        uint256 amountSold,
        address sale
    ) internal {
        if (totalTokens < amountSold || totalTokens == 0) {
            revert InvalidDistributeParameters();
        }
        ERC20PresetMinterPauser token = ERC20PresetMinterPauser(_token);
        // Send tokens to be sold to the sale.
        if (sale != address(0)) {
            token.mint(sale, amountSold);
        }
        uint256 sznsDaoRake = totalTokens / SZNS_DAO_RAKE_DIVISOR;
        // Send a small amount of the Album tokens as a rake to the szns dao.
        token.mint(SZNS_DAO, sznsDaoRake);
        // Send the rest of the tokens to the Album creator.
        token.mint(msg.sender, (totalTokens - amountSold) - sznsDaoRake);
    }
}