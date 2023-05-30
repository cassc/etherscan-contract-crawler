//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Variety.sol';

/// @title VarietyRepot Contract
/// @author Simon Fremaux (@dievardump)
contract VarietyRepot is Variety {
    event SeedlingsRepoted(address user, uint256[] ids);

    // this is the address we will repot tokens from
    address public oldVariety;

    // during the first 3 days after the start of migration
    // we do not allow people to name, so people with names
    // in the old contract have time to migrate with theirs
    uint256 public disabledNamingUntil;

    /// @notice constructor
    /// @param name_ name of the contract (see ERC721)
    /// @param symbol_ symbol of the contract (see ERC721)
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param openseaProxyRegistry_ OpenSea's proxy registry to allow gas-less listings - can be address(0)
    /// @param sower_ Sower contract
    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        address openseaProxyRegistry_,
        address sower_,
        address oldVariety_
    ) Variety(name_, symbol_, contractURI_, openseaProxyRegistry_, sower_) {
        sower = sower_;

        if (address(0) != oldVariety_) {
            oldVariety = oldVariety_;
        }

        // during 3 days, naming will be disabled as to give time to people to migrate from the old contract
        // to the new and keep their name
        disabledNamingUntil = block.timestamp + 3 days;
    }

    /// @inheritdoc Variety
    function plant(address, bytes32[] memory)
        external
        view
        override
        onlySower
        returns (uint256)
    {
        // this ensure that noone, even Sower, can directly mint tokens on this contract
        // they can only be created through the repoting method
        revert('No direct planting, only repot.');
    }

    /// @notice Function allowing an owner to set the seedling name
    ///         User needs to be extra careful. Some characters might completly break the token.
    ///         Since the metadata are generated in the contract.
    ///         if this ever happens, you can simply reset the name to nothing or for something else
    /// @dev sender must be tokenId owner
    /// @param tokenId the token to name
    /// @param seedlingName the name
    function setName(uint256 tokenId, string memory seedlingName)
        external
        override
    {
        require(
            block.timestamp > disabledNamingUntil,
            'Naming feature disabled.'
        );
        require(ownerOf(tokenId) == msg.sender, 'Not token owner.');
        _setName(tokenId, seedlingName);
    }

    /// @notice Checks if the string is valid (0-9a-zA-Z,- ) with no leading, trailing or consecutives spaces
    ///         This function is a modified version of the one in the Hashmasks contract
    /// @dev Explain to a developer any extra details
    /// @param str the name to validate
    /// @return if the name is valid
    function isNameValid(string memory str) public pure returns (bool) {
        bytes memory strBytes = bytes(str);
        if (strBytes.length < 1) return false;
        if (strBytes.length > 32) return false; // Cannot be longer than 32 characters
        if (strBytes[0] == 0x20) return false; // Leading space
        if (strBytes[strBytes.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar;
        bytes1 char;
        uint8 charCode;

        for (uint256 i; i < strBytes.length; i++) {
            char = strBytes[i];
            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces
            charCode = uint8(char);

            if (
                !(charCode >= 97 && charCode <= 122) && // a - z
                !(charCode >= 65 && charCode <= 90) && // A - Z
                !(charCode >= 48 && charCode <= 57) && // 0 - 9
                !(charCode == 32) && // space
                !(charCode == 44) && // ,
                !(charCode == 45) // -
            ) {
                return false;
            }

            lastChar = char;
        }

        return true;
    }

    /// @notice Slugify a name (tolower and replace all non 0-9az by -)
    /// @param str the string to keyIfy
    /// @return the key
    function slugify(string memory str) public pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory lowerCase = new bytes(strBytes.length);
        uint8 charCode;
        bytes1 char;
        for (uint256 i; i < strBytes.length; i++) {
            char = strBytes[i];
            charCode = uint8(char);

            // if 0-9, a-z use the character
            if (
                (charCode >= 48 && charCode <= 57) ||
                (charCode >= 97 && charCode <= 122)
            ) {
                lowerCase[i] = char;
            } else if (charCode >= 65 && charCode <= 90) {
                // if A-Z, use lowercase
                lowerCase[i] = bytes1(charCode + 32);
            } else {
                // for all others, return a -
                lowerCase[i] = 0x2D;
            }
        }

        return string(lowerCase);
    }

    /// @notice repot (migrate and burn) the seedlings of `users` from the old variety contract to the new one
    ///         to give them the exact same token id, seed and custom name if valid, on this contract
    ///         The old token is burned (deleted) forever from the old contract
    /// @dev we do not need to check that `user` we transferFrom is not the current contract, because _safeMint
    ///      would fail if we tried to mint the same tokenId twice
    /// @param users an array of users
    /// @param maxTokensAtOnce a limit of token to migrate at once, since a few users have strong hands
    function repotUsersSeedlings(
        address[] memory users,
        uint256 maxTokensAtOnce
    ) external {
        require(
            // only the contract owner
            msg.sender == owner() ||
                // or someone trying to migrate their own tokens can call this function
                (users.length == 1 && users[0] == msg.sender),
            'Not allowed to migrate.'
        );

        Variety oldVariety_ = Variety(oldVariety);

        address me = address(this);
        address user;
        uint256 migrated;
        for (uint256 j; j < users.length && (migrated < maxTokensAtOnce); j++) {
            user = users[j];

            uint256 userBalance = oldVariety_.balanceOf(user);

            if (userBalance == 0) continue;

            uint256 end = userBalance;
            // some users might have too many tokens to do that in one transaction
            if (userBalance > (maxTokensAtOnce - migrated)) {
                end = (maxTokensAtOnce - migrated);
            }

            uint256[] memory ids = new uint256[](end);
            uint256 tokenId;
            bytes32 seed;
            bytes32 slugBytes;
            string memory seedlingName;

            for (uint256 i; i < end; i++) {
                // get the last token id owned by the user
                // this is a bit cheaper than always getting index 0
                // because when removing last there is no "reorg" in the EnumerableSet
                tokenId = oldVariety_.tokenOfOwnerByIndex(
                    user,
                    userBalance - (i + 1) // this takes the last id in the user list
                );

                // get the token seed
                seed = oldVariety_.getTokenSeed(tokenId);

                // get the token name
                seedlingName = oldVariety_.getName(tokenId);

                // burn the old token first
                oldVariety_.burn(tokenId);

                // create the same token id in this contract for this user
                _safeMint(user, tokenId, '');

                // set exact same seed
                tokenSeed[tokenId] = seed;

                // if the seedling had a name and the name is valid
                if (
                    bytes(seedlingName).length > 0 && isNameValid(seedlingName)
                ) {
                    slugBytes = keccak256(bytes(slugify(seedlingName)));
                    // and is not already used
                    if (!usedNames[slugBytes]) {
                        // then use it
                        usedNames[slugBytes] = true;
                        names[tokenId] = seedlingName;
                    }
                }

                ids[i] = tokenId;
            }

            migrated += end;
            emit SeedlingsRepoted(user, ids);
        }
    }

    /// @dev allows to set a name internally.
    ///      checks that the name is valid and not used, else throws
    /// @param tokenId the token to name
    /// @param seedlingName the name
    function _setName(uint256 tokenId, string memory seedlingName) internal {
        bytes32 slugBytes;

        // if the name is not empty, require that it's valid and not used
        if (bytes(seedlingName).length > 0) {
            require(isNameValid(seedlingName) == true, 'Invalid name.');

            // also requires the name is not already used
            slugBytes = keccak256(bytes(slugify(seedlingName)));
            require(usedNames[slugBytes] == false, 'Name already used.');

            // set as used
            usedNames[slugBytes] = true;
        }

        // if it already has a name, mark the old name as unused
        string memory oldName = names[tokenId];
        if (bytes(oldName).length > 0) {
            slugBytes = keccak256(bytes(slugify(oldName)));
            usedNames[slugBytes] = false;
        }

        names[tokenId] = seedlingName;
    }
}