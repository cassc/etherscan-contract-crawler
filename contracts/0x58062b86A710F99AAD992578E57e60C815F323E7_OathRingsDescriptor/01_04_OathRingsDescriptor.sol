// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import { Base64 } from 'base64-sol/base64.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract OathRingsDescriptor is Ownable {
    string[2] public __attributes = ['Role', 'Access Pass'];
    string public __collectionPrefix = 'Oath Ring #';

    string public councilImage = 'ipfs://bafybeia77wnwguesvfvmq6hemepm2ugk46gv3h6cowihqrqzruy6leik4i';
    string public guildImage = 'ipfs://bafybeia77wnwguesvfvmq6hemepm2ugk46gv3h6cowihqrqzruy6leik4i';
    string public councilAnimationUrl = 'ipfs://bafybeihvsottfphhges3wubdomvplyhbktcd2reovbyr5fmytemaadcgvy';
    string public guildAnimationUrl = 'ipfs://bafybeihvsottfphhges3wubdomvplyhbktcd2reovbyr5fmytemaadcgvy';
    string public councilPrefix = 'Council ';
    string public councilDetails =
        'funDAOmental is an open ecosystem working on cooperative coordination. '
        'The Oath Rings are a set of 1337 NFTs that unlock access to the funDAOmental governance system '
        'and reward aligned contributors with a long-term interest in our work. '
        'Each of the 337 Council Oath Rings additionally provide a seat on our council, '
        'as well as unique holder benefits and deep access to our community, ecosystem, team, and work.';
    string public guildPrefix = 'Guild ';
    string public guildDetails =
        'funDAOmental is an open ecosystem working on cooperative coordination. '
        'The Oath Rings are a set of 1337 NFTs that unlock access to the funDAOmental governance system '
        'and reward aligned contributors with a long-term interest in our work.';
    struct TokenURIParams {
        string name;
        string description;
        string[2] attributes;
        string[2] attributeValues;
        string image;
        string animationUrl;
    }

    /**
     * @notice Set the councilImage IPFS image.
     * @dev Only callable by the owner.
     */
    function setCouncilImage(string memory image_) external onlyOwner {
        councilImage = image_;
    }

    /**
     * @notice Set the councilImage IPFS image.
     * @dev Only callable by the owner.
     */
    function setCouncilAnimationUrl(string memory animationUrl_) external onlyOwner {
        councilAnimationUrl = animationUrl_;
    }

    /**
     * @notice Set the Image IPFS image.
     * @dev Only callable by the owner.
     */
    function setGuildImage(string memory image_) external onlyOwner {
        guildImage = image_;
    }

    /**
     * @notice Set the annimation ipfs.
     * @dev Only callable by the owner.
     */
    function setGuildAnimationUrl(string memory animationUrl_) external onlyOwner {
        guildAnimationUrl = animationUrl_;
    }

    /**
     * @notice Set the CouncilDetails text.
     * @dev Only callable by the owner.
     */
    function setCouncilDetails(string memory details_) external onlyOwner {
        councilDetails = details_;
    }

    /**
     * @notice Set the CouncilDetails text.
     * @dev Only callable by the owner.
     */
    function setGuildDetails(string memory details_) external onlyOwner {
        guildDetails = details_;
    }

    /**
     * @notice Set the CouncilPrefix.
     * @dev Only callable by the owner.
     */
    function setCouncilPrefix(string memory prefix_) external onlyOwner {
        councilPrefix = prefix_;
    }

    /**
     * @notice Set the GuildPrefix.
     * @dev Only callable by the owner.
     */
    function setGuildPrefix(string memory prefix_) external onlyOwner {
        guildPrefix = prefix_;
    }

    /**
     * @notice Construct an ERC721 token attributes.
     */
    function _generateAttributes(TokenURIParams memory params) internal pure returns (string memory attributes) {
        string memory _attributes = '[';
        if (params.attributes.length > 0) {
            string[2] memory att = params.attributes;
            string[2] memory attVal = params.attributeValues;
            for (uint256 i = 0; i < att.length; i++) {
                if (i == 0) {
                    _attributes = string(
                        abi.encodePacked(_attributes, '{"trait_type":"', att[i], '","value":"', attVal[i], '"}')
                    );
                } else {
                    _attributes = string(
                        abi.encodePacked(_attributes, ',{"trait_type":"', att[i], '","value":"', attVal[i], '"}')
                    );
                }
            }
            _attributes = string(abi.encodePacked(_attributes, ']'));
            return _attributes;
        }
        // empty array

        return string(abi.encodePacked(_attributes, ']'));
    }

    /**
     * @notice Construct an ERC721 token URI.
     */
    function constructTokenURI(TokenURIParams memory params) public pure returns (string memory) {
        string memory attributes = _generateAttributes(params);
        // prettier-ignore
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                        '{"name":"', params.name, '"',
                        ',"description":"', params.description, '"',
                        ',"attributes":', attributes,'',
                        ',"image":"', params.image, '"',
                        ',"animation_url":"', params.animationUrl, '"}')
                    )
                )
            )
        );
    }

    /**
     * @notice Given a name, description, and seed, construct a base64 encoded data URI.
     */
    function genericDataURI(string memory tokenId, bool isCouncil) external view returns (string memory) {
        return constructTokenURI(_getTokenURIParams(tokenId, isCouncil));
    }

    /**
     * @notice Given a name, description, and seed, construct a base64 encoded data URI.
     */
    function _getTokenURIParams(string memory tokenId, bool isCouncil) internal view returns (TokenURIParams memory) {
        string memory _prefix = guildPrefix;
        string memory _details = guildDetails;
        string memory _image = guildImage;
        string memory _annimationUrl = guildAnimationUrl;
        string[2] memory _attributeValues = ['Guild', 'False'];

        // overwrite for council role
        if (isCouncil) {
            _prefix = councilPrefix;
            _details = councilDetails;
            _image = councilImage;
            _attributeValues = ['Council', 'True'];
            _annimationUrl = councilAnimationUrl;
        }

        _prefix = string(abi.encodePacked(_prefix, __collectionPrefix, tokenId));
        return
            TokenURIParams({
                name: _prefix,
                description: _details,
                attributes: __attributes,
                attributeValues: _attributeValues,
                image: _image,
                animationUrl: _annimationUrl
            });
    }
}