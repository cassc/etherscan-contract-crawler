// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/IGenesisToken.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * @title AvatarToken
 *
 */
contract AvatarToken is ERC721Enumerable, ReentrancyGuard, AccessControl, Pausable {
    using Strings for uint256;

    /// Seed used inside random function
    uint256 public randomSeed;

    /// Controls if tokens can be burned or not. Default to false
    bool public canBurn;

    /// Token URI - updated in constructor
    string private baseURI;

    /// Genesis Token is needed to mint an Avatar Token and it is set in constructor
    IGenesisToken public genesisToken;

    /// Robot supply. Genesis token categories from 1 to 10
    uint256[11] public robotsSupply = [0, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100];

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` for the token and `uri`.
     *      It also sets the Admin role and GenesisToken address.
     */
    constructor(address genesisTokenAddress, string memory _uri) ERC721("HUXLEY Robots", "ROBOTS") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        genesisToken = IGenesisToken(genesisTokenAddress);

        baseURI = _uri;

        _pause();
    }

    /**
     * @dev To redeem a robot user needs to have at least one Genesis Token.     
     * @param _category Genesis token category between 1 and 10.
     */
    function redeemAndMint(uint256 _category) external nonReentrant whenNotPaused {
        require(1 <= _category, "AT: Category should be >= 1");
        require(_category <= 10, "AT: Category should be <= 10");

        uint256 supplyLeft = robotsSupply[_category];
        require(supplyLeft > 0, "AT: No supply left");

        // updates robots supply
        robotsSupply[_category] = supplyLeft - 1;

        // burn genesis token
        genesisToken.redeem(msg.sender, _category);

        // mint avatar token
        uint256 tokenId = getRandomTokenId(_category);
        super._safeMint(msg.sender, tokenId);
    }

    /**
     * @dev Get a random token id for the specific <b>_category</b>.
     *      If it was already minted, get the next available one.
     * @param _category Category to mint avatar
     * @return randomTokenId A random token id
     */
    function getRandomTokenId(uint256 _category) private view returns (uint256 randomTokenId) {
        uint256 maxValue = 100 * _category;
        uint256 minValue = maxValue - 99; // first number of the category. if category is 2, it would be 101.
        unchecked {
            randomTokenId =
                uint256(
                    keccak256(
                        abi.encode(
                            keccak256(
                                abi.encodePacked(
                                    msg.sender,
                                    tx.origin,
                                    gasleft(),
                                    randomSeed,
                                    block.timestamp,
                                    block.number,
                                    blockhash(block.number),
                                    blockhash(block.number - 100)
                                )
                            )
                        )
                    )
                ) %
                100;

            // randomTokenId is a number from 0 to 99.
            // final result is randomTokenId + minValue
            // if minValue is 301 and randomTokenId is 56, final result is 357
            randomTokenId = randomTokenId + minValue;
        }

        // Returns the random number found if it wasnt minted already.
        // If it was already minted, get the next available number. If no number is available, it should fail.
        if (!_exists(randomTokenId)) {
            return randomTokenId;
        } else {
            // control is 100 tokens per category
            uint256 control = randomTokenId + 99;

            // Loop starts at the next token id (randomTokenId + 1).
            // If it is greater than maxValue, it subtracts 100.
            for (uint256 i = randomTokenId + 1; i <= control; i++) {
                uint256 index = i;
                if (index > maxValue) {
                    index = index - 100;
                }

                if (!_exists(index)) {
                    return index;
                }
            }

            revert("AT: No available token number found");
        }
    }

    /**
     * @dev Returns all supply lefted
     * @return supplyLeftCat1 Supply lefted for category 1
     * @return supplyLeftCat2 Supply lefted for category 2
     * @return supplyLeftCat3 Supply lefted for category 3
     * @return supplyLeftCat4 Supply lefted for category 4
     * @return supplyLeftCat5 Supply lefted for category 5
     * @return supplyLeftCat6 Supply lefted for category 6
     * @return supplyLeftCat7 Supply lefted for category 7
     * @return supplyLeftCat8 Supply lefted for category 8
     * @return supplyLeftCat9 Supply lefted for category 9
     * @return supplyLeftCat10 Supply lefted for category 10
     */
    function getAllSupplyLeft()
        external
        view
        returns (
            uint256 supplyLeftCat1,
            uint256 supplyLeftCat2,
            uint256 supplyLeftCat3,
            uint256 supplyLeftCat4,
            uint256 supplyLeftCat5,
            uint256 supplyLeftCat6,
            uint256 supplyLeftCat7,
            uint256 supplyLeftCat8,
            uint256 supplyLeftCat9,
            uint256 supplyLeftCat10
        )
    {
        supplyLeftCat1 = robotsSupply[1];
        supplyLeftCat2 = robotsSupply[2];
        supplyLeftCat3 = robotsSupply[3];
        supplyLeftCat4 = robotsSupply[4];
        supplyLeftCat5 = robotsSupply[5];
        supplyLeftCat6 = robotsSupply[6];
        supplyLeftCat7 = robotsSupply[7];
        supplyLeftCat8 = robotsSupply[8];
        supplyLeftCat9 = robotsSupply[9];
        supplyLeftCat10 = robotsSupply[10];
    }

    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory uri = _baseURI();

        return
            bytes(uri).length > 0
                ? string(
                    abi.encodePacked(uri, _tokenId.toString())
                )
                : "";
    }

    /// @dev IP Licenses 
    function IPLicensesIncluded() public pure returns(string memory) {
        return "Personal Use, Commercial Display, Merchandising";
    }

    /// @dev Update random seed and unpause contract
    function startMinting(uint256 _randomSeed) public onlyRole(DEFAULT_ADMIN_ROLE) {
        randomSeed = _randomSeed;
        _unpause();
    }

    /// @dev Update random seed
    function updateSeedValue(uint256 _randomSeed) public onlyRole(DEFAULT_ADMIN_ROLE) {
        randomSeed = _randomSeed;
    }

    /// @dev Sets URI for Avatar Token
    function setBaseURI(string memory _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _uri;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 _tokenId) public virtual {
        require(canBurn, "AT: is not burnable");

        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), _tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        super._burn(_tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @dev Sets if it is allowed to burn tokens. Default is 'false'. Only Minter can call this function.
    function setCanBurn(bool _canBurn) external onlyRole(DEFAULT_ADMIN_ROLE) {
        canBurn = _canBurn;
    }

    /// @dev Pause redeemAndMint()
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @dev Unpause redeemAndMint()
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}