// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./ERC1155NFTBase.sol";
import "../ChainLinkRandom.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ERC1155NFTContract is
    ERC1155NFTBase,
    ChainLinkRandom,
    ReentrancyGuard
{
    using Strings for uint256;

    bool internal revealed;

    constructor(
        address _VRFCoordinator,
        address _LINKToken,
        bytes32 _keyHash,
        string memory _blankURI,
        uint256 _supply,
        uint256 _price,
        uint256 _maxMint
    )
        public
        ERC1155NFTBase(_blankURI, _supply, _price, _maxMint)
        ChainLinkRandom(_VRFCoordinator, _LINKToken, _keyHash)
    {}

    /**
     * @dev reveal metadata of tokens.
     * @dev only can call one time, and only owner can call it.
     * @dev function will request to chainlink oracle and receive random number.
     * @dev contract will get this number by fulfillRandomness function.
     * @dev You should transfer 2 LINK token to contract, before call this function
     */
    function reveal() public onlyOwner {
        require(!revealed, "You have already generated a random seed");
        require(
            bytes(baseMetadataURI).length > 0,
            "You should set baseURI first"
        );
        revealed = true;
        _generateRandomSeed();
    }

    /**
     * @dev query metadata id of token
     * @notice only know after owner owner create `seed`
     * @param tokenId The id of token you want to query
     */
    function deterministic(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        uint256[] memory metaIds = new uint256[](TOTAL_SUPPLY);
        uint256[] memory randomArray = new uint256[](8);

        for (uint256 i = 0; i < TOTAL_SUPPLY; i++) {
            metaIds[i] = i;
        }

        // shuffle meta id
        for (uint256 i = 0; i < TOTAL_SUPPLY; i++) {
            /**
             * Get 256 bit random number
             * Split it into 8 parts (32 bit random number)
             */
            if (i % 8 == 0) {
                uint256 randomNumber = generateRandomNumber(i);
                randomArray[0] =
                    uint256(
                        randomNumber &
                            0xffffffff00000000000000000000000000000000000000000000000000000000
                    ) %
                    (TOTAL_SUPPLY);
                randomArray[1] =
                    uint256(
                        randomNumber &
                            0x00000000ffffffff000000000000000000000000000000000000000000000000
                    ) %
                    (TOTAL_SUPPLY);
                randomArray[2] =
                    uint256(
                        randomNumber &
                            0x0000000000000000ffffffff0000000000000000000000000000000000000000
                    ) %
                    (TOTAL_SUPPLY);
                randomArray[3] =
                    uint256(
                        randomNumber &
                            0x000000000000000000000000ffffffff00000000000000000000000000000000
                    ) %
                    (TOTAL_SUPPLY);
                randomArray[4] =
                    uint256(
                        randomNumber &
                            0x00000000000000000000000000000000ffffffff000000000000000000000000
                    ) %
                    (TOTAL_SUPPLY);
                randomArray[5] =
                    uint256(
                        randomNumber &
                            0x0000000000000000000000000000000000000000ffffffff0000000000000000
                    ) %
                    (TOTAL_SUPPLY);
                randomArray[6] =
                    uint256(
                        randomNumber &
                            0x000000000000000000000000000000000000000000000000ffffffff00000000
                    ) %
                    (TOTAL_SUPPLY);
                randomArray[7] =
                    uint256(
                        randomNumber &
                            0x00000000000000000000000000000000000000000000000000000000ffffffff
                    ) %
                    (TOTAL_SUPPLY);
            }

            uint256 j = randomArray[i % 8];
            (metaIds[i], metaIds[j]) = (metaIds[j], metaIds[i]);
        }

        return metaIds[tokenId].toString();
    }

    /**
     * @dev query tokenURI of token Id
     * @dev before reveal will return default URI
     * @dev after reveal return token URI of this token on IPFS
     * @param tokenId The id of token you want to query
     */

    function uri(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        require(tokenId < nextIndex(), "URI query for nonexistant token");

        // before reveal, nobody know what happened. Return _blankURI
        if (seed == 0) {
            return blankURI;
        }

        // after reveal, you can know your know.
        return
            string(abi.encodePacked(baseMetadataURI, deterministic(tokenId)));
    }

    /**
     * @dev mint token in sale period
     */
    function mintTokenOnSale(uint256 numberToken)
        external
        payable
        nonReentrant
        mintable(numberToken)
    {
        _mintOnSale(_msgSender(), numberToken);
    }

    /**
     * @dev mint token in pre sale period
     */
    function mintTokenOnPreSale(uint256 numberToken)
        external
        payable
        nonReentrant
        mintable(numberToken)
    {
        _mintPreSale(_msgSender(), numberToken);
    }

    /**
     * @dev Airdrop ether to a list of address
     * @param _to List of address
     * @param _value List of value
     */
    function multiAirdrop(address[] calldata _to, uint256[] calldata _value)
        public
        onlyOwner
        returns (bool _success)
    {
        // input validation
        assert(_to.length == _value.length);
        assert(_to.length <= 255);

        // loop through to addresses and send value
        for (uint8 i = 0; i < _to.length; i++) {
            payable(_to[i]).transfer(_value[i]);
        }

        return true;
    }
}