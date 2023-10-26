/*
                            __;φφφ≥,,╓╓,__
                           _φ░░░░░░░░░░░░░φ,_
                           φ░░░░░░░░░░░░╚░░░░_
                           ░░░░░░░░░░░░░░░▒▒░▒_
                          _░░░░░░░░░░░░░░░░╬▒░░_
    _≤,                    _░░░░░░░░░░░░░░░░╠░░ε
    _Σ░≥_                   `░░░░░░░░░░░░░░░╚░░░_
     _φ░░                     ░░░░░░░░░░░░░░░▒░░
       ░░░,                    `░░░░░░░░░░░░░╠░░___
       _░░░░░≥,                 _`░░░░░░░░░░░░░░░░░φ≥, _
       ▒░░░░░░░░,_                _ ░░░░░░░░░░░░░░░░░░░░░≥,_
      ▐░░░░░░░░░░░                 φ░░░░░░░░░░░░░░░░░░░░░░░▒,
       ░░░░░░░░░░░[             _;░░░░░░░░░░░░░░░░░░░░░░░░░░░
       \░░░░░░░░░░░»;;--,,. _  ,░░░░░░░░░░░░░░░░░░░░░░░░░░░░░Γ
       _`░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░φ,,
         _"░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░"=░░░░░░░░░░░░░░░░░
            Σ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░_    `╙δ░░░░Γ"  ²░Γ_
         ,φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░_
       _φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░φ░░≥_
      ,▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░≥
     ,░░░░░░░░░░░░░░░░░╠▒░▐░░░░░░░░░░░░░░░╚░░░░░≥
    _░░░░░░░░░░░░░░░░░░▒░░▐░░░░░░░░░░░░░░░░╚▒░░░░░
    φ░░░░░░░░░░░░░░░░░φ░░Γ'░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░░░░░░░░░░░░░░░░░░_ ░░░░░░░░░░░░░░░░░░░░░░░░[
    ╚░░░░░░░░░░░░░░░░░░░_  └░░░░░░░░░░░░░░░░░░░░░░░░
    _╚░░░░░░░░░░░░░▒"^     _7░░░░░░░░░░░░░░░░░░░░░░Γ
     _`╚░░░░░░░░╚²_          \░░░░░░░░░░░░░░░░░░░░Γ
         ____                _`░░░░░░░░░░░░░░░Γ╙`
                               _"φ░░░░░░░░░░╚_
                                 _ `""²ⁿ""

        ██╗         ██╗   ██╗    ██╗  ██╗    ██╗   ██╗
        ██║         ██║   ██║    ╚██╗██╔╝    ╚██╗ ██╔╝
        ██║         ██║   ██║     ╚███╔╝      ╚████╔╝ 
        ██║         ██║   ██║     ██╔██╗       ╚██╔╝  
        ███████╗    ╚██████╔╝    ██╔╝ ██╗       ██║   
        ╚══════╝     ╚═════╝     ╚═╝  ╚═╝       ╚═╝   
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IRoyaltiesProvider.sol";
import "../RoyaltiesV1Luxy.sol";
import "../RoyaltiesV2Rarible.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../tokens/ERC2981/IERC2981.sol";
/**
* @title RoyaltiesRegistry
* @dev Royalties Reg contract of luxy
* @custom:dev-run-script scripts/deploy-newRoyaltiesRegistry.js
**/
contract RoyaltiesRegistry is IRoyaltiesProvider, OwnableUpgradeable {
    event RoyaltiesSetForToken(
        address indexed token,
        uint256 indexed tokenId,
        LibPart.Part[] royalties
    );
    event RoyaltiesSetForContract(
        address indexed token,
        LibPart.Part[] royalties
    );

    struct RoyaltiesSet {
        bool initialized;
        LibPart.Part[] royalties;
    }

    mapping(bytes32 => RoyaltiesSet) public royaltiesByTokenAndTokenId;
    mapping(address => RoyaltiesSet) public royaltiesByToken;
    mapping(address => address) public royaltiesProviders;

    function __RoyaltiesRegistry_init() external initializer {
        __Ownable_init_unchained();
    }

    function setProviderByToken(address token, address provider) external {
        checkOwner(token);
        royaltiesProviders[token] = provider;
    }

    function setRoyaltiesByToken(
        address token,
        LibPart.Part[] memory royalties
    ) external {
        checkOwner(token);
        uint256 sumRoyalties = 0;
        delete royaltiesByToken[token];

        for (uint256 i = 0; i < royalties.length; i++) {
            require(
                royalties[i].account != address(0x0),
                "RoyaltiesByToken recipient should be present"
            );
            require(
                royalties[i].value != 0,
                "Royalty value for RoyaltiesByToken should be > 0"
            );

            // Check if the new royalty is already present in the array
            for (
                uint256 j = 0;
                j < royaltiesByToken[token].royalties.length;
                j++
            ) {
                require(
                    royalties[i].account !=
                        royaltiesByToken[token].royalties[j].account,
                    "Duplicate account detected in royalties"
                );
            }

            royaltiesByToken[token].royalties.push(royalties[i]);
            sumRoyalties += royalties[i].value;
        }

        require(
            sumRoyalties <= 3000,
            "Set by token royalties sum more than 30%"
        );
        royaltiesByToken[token].initialized = true;
        emit RoyaltiesSetForContract(token, royalties);
    }

    function getRoyaltiesByToken(
        address token
    ) external view returns (LibPart.Part[] memory) {
        return royaltiesByToken[token].royalties;
    }

    function getRoyaltiesByTokenAndTokenId(
        address token,
        uint256 tokenId
    ) external view returns (LibPart.Part[] memory) {
        return
            royaltiesByTokenAndTokenId[keccak256(abi.encode(token, tokenId))]
                .royalties;
    }

    function checkOwner(address token) internal view {
        if ((owner() != _msgSender())) {
            try OwnableUpgradeable(token).owner() returns (address result) {
                if (result != _msgSender()) {
                    revert("Sender is not owner of the token");
                }
            } catch {
                revert("Token owner not detected");
            }
        }
    }

    function getRoyalties(
        address token,
        uint256 tokenId
    ) external override returns (LibPart.Part[] memory) {
        RoyaltiesSet memory royaltiesSetNFT = royaltiesByTokenAndTokenId[
            keccak256(abi.encode(token, tokenId))
        ];
        RoyaltiesSet memory royaltiesSetToken = royaltiesByToken[token];
        uint totalRoyalties = royaltiesSetNFT.royalties.length +
            royaltiesSetToken.royalties.length;
        LibPart.Part[] memory combinedRoyalties;

        if (royaltiesSetNFT.initialized && royaltiesSetToken.initialized) {
            combinedRoyalties = new LibPart.Part[](
                totalRoyalties
            );
            for (uint256 i = 0; i < royaltiesSetToken.royalties.length; i++) {
                combinedRoyalties[i] = royaltiesSetToken.royalties[i];
            }

            for (uint256 i = 0; i < royaltiesSetNFT.royalties.length; i++) {
                combinedRoyalties[
                    royaltiesSetToken.royalties.length + i
                ] = royaltiesSetNFT.royalties[i];
            }

            return combinedRoyalties;
        } else if (
            royaltiesSetNFT.initialized
        ) {
            return royaltiesSetNFT.royalties;
        }
        (
            bool result,
            LibPart.Part[] memory resultRoyalties
        ) = providerExtractor(token, tokenId);
        if (result == false) {
            resultRoyalties = royaltiesFromContract(token, tokenId);
        }
        totalRoyalties =
            resultRoyalties.length +
            royaltiesSetToken.royalties.length;

        setRoyaltiesCacheByTokenAndTokenId(token, tokenId, resultRoyalties);

        combinedRoyalties = new LibPart.Part[](
            totalRoyalties
        );
        if (resultRoyalties.length > 0) {
            for (uint256 i = 0; i < royaltiesSetToken.royalties.length; i++) {
                combinedRoyalties[i] = royaltiesSetToken.royalties[i];
            }

            for (uint256 i = 0; i < resultRoyalties.length; i++) {
                combinedRoyalties[
                    royaltiesSetToken.royalties.length + i
                ] = resultRoyalties[i];
            }
            return combinedRoyalties;
        }
        if (royaltiesSetToken.initialized) {
            return royaltiesSetToken.royalties;
        }
    }

    function setRoyaltiesCacheByTokenAndTokenId(
        address token,
        uint256 tokenId,
        LibPart.Part[] memory royalties
    ) internal {
        uint256 sumRoyalties = 0;
        bytes32 key = keccak256(abi.encode(token, tokenId));
        delete royaltiesByTokenAndTokenId[key].royalties;
        for (uint256 i = 0; i < royalties.length; i++) {
            require(
                royalties[i].account != address(0x0),
                "RoyaltiesByTokenAndTokenId recipient should be present"
            );
            require(
                royalties[i].value != 0,
                "Royalty value for RoyaltiesByTokenAndTokenId should be > 0"
            );
            royaltiesByTokenAndTokenId[key].royalties.push(royalties[i]);
            sumRoyalties += royalties[i].value;
        }
        require(
            sumRoyalties <= 6800,
            "Set by token and tokenId royalties sum more, than 68%"
        );
        royaltiesByTokenAndTokenId[key].initialized = true;
        emit RoyaltiesSetForToken(token, tokenId, royalties);
    }

    function royaltiesFromContract(
        address token,
        uint256 tokenId
    ) internal view returns (LibPart.Part[] memory) {
        if (
            IERC165Upgradeable(token).supportsInterface(
                type(RoyaltiesV1Luxy).interfaceId
            )
        ) {
            RoyaltiesV1Luxy v1 = RoyaltiesV1Luxy(token);
            try v1.getRoyalties(tokenId) returns (
                LibPart.Part[] memory result
            ) {
                return result;
            } catch {}
        } else if (
            IERC165Upgradeable(token).supportsInterface(
                type(RoyaltiesV2Rarible).interfaceId
            )
        ) {
            RoyaltiesV2Rarible v2 = RoyaltiesV2Rarible(token);
            try v2.getRaribleV2Royalties(tokenId) returns (
                LibPart.Part[] memory result
            ) {
                return result;
            } catch {}
        } else if (
            IERC165Upgradeable(token).supportsInterface(
                type(IERC2981).interfaceId
            )
        ) {
            IERC2981 standard = IERC2981(token);
            try standard.royaltyInfo(tokenId, 10000) returns (
                address receiver,
                uint256 royaltyAmount
            ) {
                LibPart.Part[] memory result = new LibPart.Part[](1);
                result[0].account = payable(receiver);
                result[0].value = uint96(royaltyAmount);
                return result;
            } catch {}
        }
        return new LibPart.Part[](0);
    }

    function providerExtractor(
        address token,
        uint256 tokenId
    ) public returns (bool result, LibPart.Part[] memory royalties) {
        result = false;
        address providerAddress = royaltiesProviders[token];
        if (providerAddress != address(0x0)) {
            IRoyaltiesProvider provider = IRoyaltiesProvider(providerAddress);
            try provider.getRoyalties(token, tokenId) returns (
                LibPart.Part[] memory royaltiesByProvider
            ) {
                royalties = royaltiesByProvider;
                result = true;
            } catch {}
        }
    }

    uint256[50] private __gap;
}