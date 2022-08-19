// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/IGenesisToken.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * @title HumansToken
 *
 */
contract HumansToken is ERC721Enumerable, Ownable {
    using SignatureChecker for address;
    using Strings for uint256;

    /// Avatar Token tokens owners can mint a Humans Token (up to 1.000)
    IERC721 private avatarToken;

    /// Genesis Token is needed to mint a Humans Token and it is set in constructor
    IGenesisToken private genesisToken;

    /// Token URI 
    string private baseURI;

    /// Controls if tokens can be burned or not. Default to false
    bool public canBurn;

    /// @dev Sets when Robots Owners can mint
    bool public canMintUsingRobots;

    /// @dev Sets when can mint using Genesis Token
    bool public canMintUsingGenesis;

    /// @dev Sets when priority minting is allowed
    bool public canPriorityMint;

    /// Seed used inside random function
    uint256 private randomSeed;

    /// @dev address used to sign priority list addresses
    address private signer;

    /// @dev mapping of Robots redemptions - robot tokenId -> true/false
    mapping(uint256 => bool) public robotsRedemptions;

    /// @dev mapping of Priority address -> quantityRedeemed
    mapping(address => uint256) public priorityQtyRedeemed;

    /// Human supply. Genesis token categories from 1 to 10
    uint256[11] private humansSupplyRobotsOwners = [
        0,
        100,
        100,
        100,
        100,
        100,
        100,
        100,
        100,
        100,
        100
    ];

    /// Human supply. Genesis token categories from 1 to 10
    uint256[11] private humansSupply = [0, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200];

    event RobotMintExecuted(address _sender, uint256 _tokenId, uint256 _humanTokenId);

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` for the token and `uri`.
     *      It also sets the Admin role and GenesisToken address.
     */
    constructor(address genesisTokenAddress, address avatarTokenAddress)
        ERC721("HUXLEY Humans", "HUMANS")
    {
        genesisToken = IGenesisToken(genesisTokenAddress);
        avatarToken = IERC721(avatarTokenAddress);
    }

    /**
     * @dev To redeem a Human Token, user needs to have at least one Robot Token
     * @param _robotTokenId Token Id of a Robot Token
     */
    function redeemAndMintRobot(uint256 _robotTokenId) external {
        require(canMintUsingRobots, "HT: Mint not allowed");
        require(avatarToken.ownerOf(_robotTokenId) == msg.sender, "HT: Not owner");
        require(robotsRedemptions[_robotTokenId] == false, "HT: Robot used");

        robotsRedemptions[_robotTokenId] = true;

        uint256 _category = 1;

        if (_robotTokenId > 100) {
            uint256 result = _robotTokenId;
            while (result > 100) {
                _category++;
                result = result - 100;
            }
        }

        // mint human token
        uint256 tokenId = _mintRobot(_category);
        emit RobotMintExecuted(msg.sender, _robotTokenId, tokenId);
    }

    function _mintRobot(uint256 _category) internal returns (uint256 tokenId) {
        uint256 supplyLeftRobotsOwners = humansSupplyRobotsOwners[_category];
        require(supplyLeftRobotsOwners > 0, "HT: No robot supply lefted");

        // updates humans supply
        humansSupplyRobotsOwners[_category] = supplyLeftRobotsOwners - 1;

        // mint Human Token
        tokenId = _mintToken(_category);
    }

    /**
     * @dev To redeem a human, user needs to have at least one Genesis Token.
     * @param _category Genesis token category between 1 and 10.
     */
    function priorityRedeemAndMint(
        uint256 _category,
        uint256 _amount,
        uint256 _quantityAllowed,
        bytes memory _signature
    ) external {
        require(canPriorityMint, "HT: Priority mint not allowed");
        uint256 qtyRedeemed = priorityQtyRedeemed[msg.sender] + _amount;
        require(qtyRedeemed <= _quantityAllowed, "HT: Over qty allowed");
        require(hasPriority(_signature, _quantityAllowed), "HT: has no priority");

        priorityQtyRedeemed[msg.sender] = qtyRedeemed;

        _mintGenesis(_category, _amount);
    }

    /**
     * @dev To redeem a human, user needs to have at least one Genesis Token.
     * @param _category Genesis token category between 1 and 10.
     */
    function redeemAndMintGenesis(uint256 _category, uint256 _amount) external {
        require(canMintUsingGenesis, "HT: Mint not allowed");
        _mintGenesis(_category, _amount);
    }

    /**
     * @dev To redeem a human, user needs to have at least one Genesis Token.
     * @param _category Genesis token category between 1 and 10.
     */
    function _mintGenesis(uint256 _category, uint256 _amount) internal {
        require(humansSupply[_category] > 0, "HT: no supply using Genesis");
        require(_amount > 0, "HT: Amount is 0");

        for (uint256 i = 1; i <= _amount; i++) {
            uint256 supplyLeft = humansSupply[_category];
            if (supplyLeft > 0) {
                // updates humans supply
                humansSupply[_category] = supplyLeft - 1;

                // burn genesis token
                genesisToken.redeem(msg.sender, _category);

                // mint human token
                _mintToken(_category);
            }
        }
    }

    function _mintToken(uint256 _category) internal returns (uint256 tokenId) {
        tokenId = getRandomTokenId(_category);
        super._safeMint(msg.sender, tokenId);
    }

    /**
     * @dev To redeem a human, user needs to have at least one Genesis Token.
     * @param _category Genesis token category between 1 and 10.
     */
    function privateMint(
        uint256 _category,
        uint256 _amount,
        bool isRobot
    ) external onlyOwner {
        for (uint256 i = 1; i <= _amount; i++) {
            if (isRobot) {
                _mintRobot(_category);
            } else {
                uint256 supplyLeft = humansSupply[_category];
                require(supplyLeft > 0, "HT: No supply lefted for private mint.");
                humansSupply[_category] = supplyLeft - 1;
                _mintToken(_category);
            }
        }
    }

    /**
     * @dev Get a random token id for the specific <b>_category</b>.
     *      If it was already minted, get the next available one.
     * @param _category Category to mint avatar
     * @return randomTokenId A random token id
     */
    function getRandomTokenId(uint256 _category) private view returns (uint256 randomTokenId) {
        uint256 maxValue = 300 * _category;
        uint256 minValue = maxValue - 299; // first number of the category. if category is 2, it would be 301.
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
                                    blockhash(block.number - 300)
                                )
                            )
                        )
                    )
                ) %
                300;

            // randomTokenId is a number from 0 to 299.
            // final result is randomTokenId + minValue
            // if minValue is 301 and randomTokenId is 256, final result is 557
            randomTokenId = randomTokenId + minValue;
        }
        
        // Returns the random number found if it wasnt minted already.
        // If it was already minted, get the next available number. If no number is available, it should fail.
        if (!_exists(randomTokenId)) {
            return randomTokenId;
        } else {
            // control is 300 tokens per category
            uint256 control = randomTokenId + 299;

            // Loop starts at the next token id (randomTokenId + 1).
            // If it is greater than maxValue, it subtracts 100.
            for (uint256 i = randomTokenId + 1; i <= control; i++) {
                uint256 index = i;
                if (index > maxValue) {
                    index = index - 300;
                }

                if (!_exists(index)) {
                    return index;
                }
            }

            revert("HT: No token number");
        }
    }

    /**
     * @dev Check if an address has priority to mint Humans Tokens.
     * @param _signature Signature to check.
     * @param _quantityAllowed Total amount that can priority mint
     */
    function hasPriority(bytes memory _signature, uint256 _quantityAllowed)
        internal
        view
        returns (bool)
    {
        bytes32 result = keccak256(abi.encodePacked(_quantityAllowed, msg.sender));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", result));
        return signer.isValidSignatureNow(hash, _signature);
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
    function getAllSupplyLeftRobotsOwners()
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
        supplyLeftCat1 = humansSupplyRobotsOwners[1];
        supplyLeftCat2 = humansSupplyRobotsOwners[2];
        supplyLeftCat3 = humansSupplyRobotsOwners[3];
        supplyLeftCat4 = humansSupplyRobotsOwners[4];
        supplyLeftCat5 = humansSupplyRobotsOwners[5];
        supplyLeftCat6 = humansSupplyRobotsOwners[6];
        supplyLeftCat7 = humansSupplyRobotsOwners[7];
        supplyLeftCat8 = humansSupplyRobotsOwners[8];
        supplyLeftCat9 = humansSupplyRobotsOwners[9];
        supplyLeftCat10 = humansSupplyRobotsOwners[10];
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
        supplyLeftCat1 = humansSupply[1];
        supplyLeftCat2 = humansSupply[2];
        supplyLeftCat3 = humansSupply[3];
        supplyLeftCat4 = humansSupply[4];
        supplyLeftCat5 = humansSupply[5];
        supplyLeftCat6 = humansSupply[6];
        supplyLeftCat7 = humansSupply[7];
        supplyLeftCat8 = humansSupply[8];
        supplyLeftCat9 = humansSupply[9];
        supplyLeftCat10 = humansSupply[10];
    }

    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "HT: URI query for invalid token");

        string memory uri = _baseURI();

        return bytes(uri).length > 0 ? string(abi.encodePacked(uri, _tokenId.toString())) : "";
    }

    /// @dev IP Licenses
    function IPLicensesIncluded() public pure returns (string memory) {
        return "Personal Use, Commercial Display, Merchandising";
    }

    /// @dev Update random seed
    function updateSeedValue(uint256 _randomSeed) public onlyOwner {
        randomSeed = _randomSeed;
    }

    /// @dev Sets URI for Avatar Token
    function setBaseURI(string memory _uri) external onlyOwner {
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
        require(canBurn, "HT: not burnable");

        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), _tokenId),
            "HT: caller is not owner nor approved"
        );
        super._burn(_tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Updates address of 'signer'
     * @param _signer  New address for 'signer'
     */
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    /// @dev Sets if it is allowed to burn tokens. Default is 'false'. Only Minter can call this function.
    function setCanBurn(bool _canBurn) external onlyOwner {
        canBurn = _canBurn;
    }

    /// @dev Sets if it is allowed to mint using Robots token ids. Default is 'false'. Only Minter can call this function.
    function setCanMintUsingRobots(bool _canMintUsingRobots) external onlyOwner {
        canMintUsingRobots = _canMintUsingRobots;
    }

    /// @dev Sets if it is allowed to mint using Genesis tokens. Default is 'false'. Only Minter can call this function.
    function setCanMintUsingGenesis(bool _canMintUsingGenesis) external onlyOwner {
        canMintUsingGenesis = _canMintUsingGenesis;
    }

    function setCanPriorityMint(bool _canPriorityMint) external onlyOwner {
        canPriorityMint = _canPriorityMint;
    }
}