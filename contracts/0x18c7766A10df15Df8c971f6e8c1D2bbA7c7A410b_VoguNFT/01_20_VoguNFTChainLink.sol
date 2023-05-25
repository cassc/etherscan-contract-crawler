pragma solidity 0.6.6;

import "./VoguNFTBase.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract VoguNFT is VoguNFTBase, VRFConsumerBase {
    event VoguSeed(uint256 seed);

    uint256 public seed;
    bytes32 internal keyHash;
    uint256 internal fee;

    string public specialURI;
    string public defaultURI;

    bool earlyMint;
    bool revealed;

    constructor(
        address _VRFCoordinator,
        address _LINKToken,
        bytes32 _keyHash,
        uint256 _mintFeePerToken,
        uint256 _maxVogu, 
        string memory _defaultURI
    )
        public
        VoguNFTBase(_mintFeePerToken, _maxVogu)
        VRFConsumerBase(_VRFCoordinator, _LINKToken)
    {
        keyHash = _keyHash;
        fee = 2 * 10**18; // 2 LINK token
        defaultURI = _defaultURI;
    }

    function setDefaultURI(string memory _defaultURI) public onlyOwner {
        defaultURI = _defaultURI;
    }

    function setSpecialURI(string memory _specicalURI) public onlyOwner {
        specialURI = _specicalURI;
    }

    /**
     * @dev mint `numberToken` for msg.sender aka who call method.
     * @param numberToken number token collector want to mint
     */
    function _mintVogu(uint256 numberToken) internal returns (bool) {
        for (uint256 i = 0; i < numberToken; i++) {
            uint256 tokenIndex = totalSupply();
            if (tokenIndex < MAX_VOGU) _safeMint(_msgSender(), tokenIndex);
        }
        return true;
    }

    function mintVogu(uint256 numberToken)
        public
        payable
        online
        mintable(numberToken)
        returns (bool)
    {
        return _mintVogu(numberToken);
    }
    /**
     * @dev reveal metadata of tokens.
     * @dev only can call one time, and only owner can call it.
     * @dev function will request to chainlink oracle and receive random number.
     * @dev contract will get this number by fulfillRandomness function. 
     * @dev You should transfer 2 LINK token to contract, before call this function
     */
    function reveal() public onlyOwner {
        require(!revealed, "You have already generated a random seed");
        require(LINK.balanceOf(address(this)) >= fee);
        requestRandomness(keyHash, fee);
        revealed = true;
    }

    /**
     * @dev receive random number from chainlink
     * @notice random number will greater than zero
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
        internal
        override
    {
        if (randomNumber > 0) seed = randomNumber;
        else seed = 1;
        emit VoguSeed(seed);
    }

    /**
     * @dev query metadata id of token
     * @notice only know after owner owner create `seed`
     * @param tokenId The id of token you want to query
     */
    function metadataOf(uint256 tokenId) public view returns (string memory) {
        require(tokenId < totalSupply(), "Token id invalid");

        if (seed == 0) return "";

        uint256[] memory metaIds = new uint256[](MAX_VOGU);
        uint256 ss = seed;

        for (uint256 i = 0; i < MAX_VOGU; i++) {
            metaIds[i] = i;
        }

        // shuffle meta id
        for (uint256 i = 5; i < MAX_VOGU; i++) {
            uint256 j = (uint256(keccak256(abi.encode(ss, i))) %
                (MAX_VOGU - 5)) + 5;
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
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(tokenId < totalSupply(), "Token not exist.");

        // special token => return URI
        if (tokenId < 5)
            return string(abi.encodePacked(specialURI, tokenId.toString()));

        // before reveal, nobody know what happened
        if (!revealed) {
            return defaultURI;
        }

        // after reveal, you can know your know.
        return string(abi.encodePacked(baseURI(), metadataOf(tokenId)));
    }

    /**
     * @dev Minted early for owner, only owner can call, use also want to provide link to 5 metadata
     * @notice You only call this one time, and it should be call when offline
     */
    function earlyMintVugo(string memory _specialURI) public offline onlyOwner {
        require(!earlyMint, "Owner minted token");
        _mintVogu(77);
        specialURI = _specialURI;
        earlyMint = true;
    }
}