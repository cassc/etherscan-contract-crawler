// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

interface IHasSecondarySaleFees {
    function getFeeBps(uint256 id) external view returns (uint256[] memory);
    function getFeeRecipients(uint256 id) external view returns (address payable[] memory);
}

contract HasSecondarySaleFees is IERC165, IHasSecondarySaleFees {
    
    event ChangeCommonRoyalty(
        address payable[] royaltyAddresses,
        uint256[] royaltiesWithTwoDecimals
    );
    
    event ChangeRoyalty(
        uint256 id,
        address payable[] royaltyAddresses,
        uint256[] royaltiesWithTwoDecimals
    );
    
    struct RoyaltyInfo {
        bool isPresent;
        address payable[] royaltyAddresses;
        uint256[] royaltiesWithTwoDecimals;
    }
    
    mapping(bytes32 => RoyaltyInfo) royaltyInfoMap;
    mapping(uint256 => bytes32) tokenRoyaltyMap;
    
    address payable[] public commonRoyaltyAddresses;
    uint256[] public commonRoyaltiesWithTwoDecimals;

    constructor(
        address payable[] memory _commonRoyaltyAddresses,
        uint256[] memory _commonRoyaltiesWithTwoDecimals
    ) {
        _setCommonRoyalties(_commonRoyaltyAddresses, _commonRoyaltiesWithTwoDecimals);
    }

    function _setRoyaltiesOf(
        uint256 _tokenId,
        address payable[] memory _royaltyAddresses,
        uint256[] memory _royaltiesWithTwoDecimals
    ) internal {
        require(_royaltyAddresses.length == _royaltiesWithTwoDecimals.length, "input length must be same");
        bytes32 key = 0x0;
        for (uint256 i = 0; i < _royaltyAddresses.length; i++) { 
            require(_royaltyAddresses[i] != address(0), "Must not be zero-address");
            key = keccak256(abi.encodePacked(key, _royaltyAddresses[i], _royaltiesWithTwoDecimals[i]));
        }
        
        tokenRoyaltyMap[_tokenId] = key;
        emit ChangeRoyalty(_tokenId, _royaltyAddresses, _royaltiesWithTwoDecimals);
        
        if (royaltyInfoMap[key].isPresent) { 
            return;
        }
        royaltyInfoMap[key] = RoyaltyInfo(
            true,
            _royaltyAddresses,
            _royaltiesWithTwoDecimals
        );
    }

    function _setCommonRoyalties(
        address payable[] memory _commonRoyaltyAddresses,
        uint256[] memory _commonRoyaltiesWithTwoDecimals
    ) internal {
        require(_commonRoyaltyAddresses.length == _commonRoyaltiesWithTwoDecimals.length, "input length must be same");
        for (uint256 i = 0; i < _commonRoyaltyAddresses.length; i++) { 
            require(_commonRoyaltyAddresses[i] != address(0), "Must not be zero-address");
        }
        
        commonRoyaltyAddresses = _commonRoyaltyAddresses;
        commonRoyaltiesWithTwoDecimals = _commonRoyaltiesWithTwoDecimals;
        
        emit ChangeCommonRoyalty(_commonRoyaltyAddresses, _commonRoyaltiesWithTwoDecimals);
    }

    function getFeeRecipients(uint256 _tokenId)
    public view override returns (address payable[] memory)
    {
        RoyaltyInfo memory royaltyInfo = royaltyInfoMap[tokenRoyaltyMap[_tokenId]];
        if (!royaltyInfo.isPresent) {
            return commonRoyaltyAddresses;
        }
        uint256 length = commonRoyaltyAddresses.length + royaltyInfo.royaltyAddresses.length;

        address payable[] memory recipients = new address payable[](length);
        for (uint256 i = 0; i < commonRoyaltyAddresses.length; i++) {
            recipients[i] = commonRoyaltyAddresses[i];
        }
        for (uint256 i = 0; i < royaltyInfo.royaltyAddresses.length; i++) {
            recipients[i + commonRoyaltyAddresses.length] = royaltyInfo.royaltyAddresses[i];
        }

        return recipients;
    }

    function getFeeBps(uint256 _tokenId) public view override returns (uint256[] memory) {
        RoyaltyInfo memory royaltyInfo = royaltyInfoMap[tokenRoyaltyMap[_tokenId]];
        if (!royaltyInfo.isPresent) {
            return commonRoyaltiesWithTwoDecimals;
        }
        uint256 length = commonRoyaltiesWithTwoDecimals.length + royaltyInfo.royaltiesWithTwoDecimals.length;

        uint256[] memory fees = new uint256[](length);
        for (uint256 i = 0; i < commonRoyaltiesWithTwoDecimals.length; i++) {
            fees[i] = commonRoyaltiesWithTwoDecimals[i];
        }
        for (uint256 i = 0; i < royaltyInfo.royaltiesWithTwoDecimals.length; i++) {
            fees[i + commonRoyaltyAddresses.length] = royaltyInfo.royaltiesWithTwoDecimals[i];
        }

        return fees;
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165)
    returns (bool)
    {
        return interfaceId == type(IHasSecondarySaleFees).interfaceId;
    }

}