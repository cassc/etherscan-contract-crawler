// SPDX-License-Identifier: MIT

/***
 *   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *   @@@@@@@@@@@@@@@@@@@@@@&#G5J7!~~~~~!7?YPB&@@@@@@@@@@@@@@@@@&BPY?7!~~~~~!7?YP#&@@@@@@@@@@@@@@@@@@@@@@@
 *   @@@@@@@@@@@@@@@@@@@#57^.                :~JG&@@@@@@@@@&BY!:.               .^[email protected]@@@@@@@@@@@@@@@@@@@
 *   @@@@@@@@@@@@@@@@&P!.                        ^[email protected]@@@@#Y^.                       .~Y#@@@@@@@@@@@@@@@@@
 *   @@@@@@@@@@@@@@&5^                             [email protected]@G.                             :J&@@@@@@@@@@@@@@@
 *   @@@@@@@@@@@@@B~                                  ?&@5.                              :[email protected]@@@@@@@@@@@@@
 *   @@@@@@@@@@@@5.                                    ^#@G.                               [email protected]@@@@@@@@@@@@
 *   @@@@@@@@@@@5.                                      :#@G.                               [email protected]@@@@@@@@@@@
 *   @@@@@@@@@@B.                      ~JYJ7.            [email protected]@?             :7JYJ~             [email protected]@@@@@@@@@@
 *   @@@@@@@@@@7..                   [email protected]@@@@#^            [email protected]#.           ~#@@@@@5.           ^&@@@@@@@@@@
 *   @@@@@@@@@#:..                   :&@@@@@@7            [email protected]@~           [email protected]@@@@@#.            [email protected]@@@@@@@@@
 *   @@@@@@@@@#...                    ^5B##G7             [email protected]@!            7G##B5^             [email protected]@@@@@@@@@
 *   @@@@@@@@@&:..                      ...               [email protected]@~              ...               [email protected]@@@@@@@@@
 *   @@@@@@@@@@7...                                       [email protected]                               ^&@@@@@@@@@@
 *   @@@@@@@@@@B....                                     [email protected]@?                                [email protected]@@@@@@@@@@
 *   @@@@@@@@@@@5....                                   ^#@P                                [email protected]@@@@@@@@@@@
 *   @@@@@@@@@@@@5.....                                ~#@G.                               [email protected]@@@@@@@@@@@@
 *   @@@@@@@@@@@@@B!.....                            .J&@5.                              ^[email protected]@@@@@@@@@@@@@
 *   @@@@@@@@@@@@@@@5~.....                        [email protected]@G:.....                        :Y&@@@@@@@@@@@@@@@
 *   @@@@@@@@@@@@@@@@&P7:.......                .^[email protected]@@@@#Y~.......                 .!5&@@@@@@@@@@@@@@@@@
 *   @@@@@@@@@@@@@@@@@@@#P?~:.......       ..^!YB&@@@@@@@@@@B57^:.......       .:~?5#@@@@@@@@@@@@@@@@@@@@
 *   @@@@@@@@@@@@@@@@@@@@@@@#BPY?7!!!!!7?J5PB&@@@@@@@@@@@@@@@@@&#G5J?7!!!!!7?J5G#&@@@@@@@@@@@@@@@@@@@@@@@
 *   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 *                    ██████╗ ██╗      █████╗ ███╗   ██╗██████╗ ███████╗██████╗ ███████╗
 *                    ╚════██╗██║     ██╔══██╗████╗  ██║██╔══██╗██╔════╝██╔══██╗██╔════╝
 *                     █████╔╝██║     ███████║██╔██╗ ██║██║  ██║█████╗  ██████╔╝███████╗
 *                     ╚═══██╗██║     ██╔══██║██║╚██╗██║██║  ██║██╔══╝  ██╔══██╗╚════██║
 *                    ██████╔╝███████╗██║  ██║██║ ╚████║██████╔╝███████╗██║  ██║███████║
 *                    ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝
 *                      
 */

/**
 * @title ThreeLandersv2
 * @author @freshdrops_io
 *
 *         ==                  
 *        =++=                 
 *      .++++++                
 *     .++++++++.    |||||||╗||||||╗ |||||||╗|||||||╗||╗  ||╗||||||╗ ||||||╗  ||||||╗ ||||||╗ |||||||╗    
 *    .++++++++++.   ||╔════╝||╔══||╗||╔════╝||╔════╝||║  ||║||╔══||╗||╔══||╗||╔═══||╗||╔══||╗||╔════╝    
 *    =++++++++++-   |||||╗  ||||||╔╝|||||╗  |||||||╗|||||||║||║  ||║||||||╔╝||║   ||║||||||╔╝|||||||╗     
 *    :++++++++++:   ||╔══╝  ||╔══||╗||╔══╝  ╚════||║||╔══||║||║  ||║||╔══||╗||║   ||║||╔═══╝ ╚════||║     
 *     :++++++++.    ||║     ||║  ||║|||||||╗|||||||║||║  ||║||||||╔╝||║  ||║╚||||||╔╝||║     |||||||║     
 *       .::::       ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚══════╝     
 *        ===-                  
 *         ++                   
 *                       
*/

pragma solidity ^0.8.13;

import "./ERC721TUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";

contract ThreeLandersv2 is
    Initializable,
    AccessControlUpgradeable,
    ERC721TUpgradeable,
    DefaultOperatorFiltererUpgradeable,
    ERC2981Upgradeable
{

    /// Base uri
    string public baseURI;

    /// Total supply
    uint256 public totalSupply;

    /// Maximum supply
    uint256 public constant MAX_SUPPLY = 10000;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory baseURI_,
        address _receiver,
        uint96 _royalty,
        uint256 startToken_
    ) public initializer {
        __ERC721T_init(_name, _symbol, startToken_);
        __AccessControl_init();
        __ERC2981_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        baseURI = baseURI_;

        _setDefaultRoyalty(_receiver, _royalty);
    }

    function initializeV2() public reinitializer(2) {
        __DefaultOperatorFilterer_init();
    }

    function name() public pure override returns (string memory) {
        return "3Landers";
    }

    function symbol() public pure override returns (string memory) {
        return "3L";
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(
            ERC721TUpgradeable,
            AccessControlUpgradeable,
            ERC2981Upgradeable
        )
        returns (bool)
    {
        return
            ERC721TUpgradeable.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function setBaseURI(
        string memory baseURI_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function airdrop(
        address[] calldata to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 toMint = to.length;
        uint256 newTotalSupply = totalSupply + toMint;
        require(
            newTotalSupply <= MAX_SUPPLY,
            "3L: Minting would exceed maximum supply"
        );

        for (uint256 i = 0; i < toMint; ) {
            _mint(to[i]);
            unchecked {
                i++;
            }
        }

        totalSupply = newTotalSupply;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}