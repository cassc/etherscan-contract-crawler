//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract GMGN is ERC1155, Ownable {
    IERC721 constant GENESIS_TOKEN_CONTRACT = IERC721(address(0x19b86299c21505cdf59cE63740B240A9C822b5E4));
    uint256 constant NORMAL_DYNAMITE_TYPE_ID = 0;
    uint256 constant RADIOACTIVE_DYNAMITE_TYPE_ID = 1;
    uint8 constant RADIOACTIVE_DYNAMITE_PRICE = 3;
    string constant URI_SUFFIX = '.json';

    error YouMustOwnAllTheTokens();
    error AlreadyClaimed();
    error InsufficientFunds();
    error OnlyTheMutationContractCanBurnTokensDirectly();
    error ClaimNotEnabled();
    error ExchangeNotEnabled();
    error InvalidTokenType();

    event Claim(uint256 indexed tokenId, address indexed from);

    struct ClaimStatus {
        uint256 tokenId;
        bool hasClaimed;
    }

    address public mutationContractAddress = address(0);

    bool public canClaim = false;
    bool public canExchange = false;

    mapping (uint256 => bool) public hasClaimed;

    constructor(string memory _uriPrefix) ERC1155(_uriPrefix) {
    }

    function claim(uint256[] memory _tokenIds) public {
        if (!canClaim) {
            revert ClaimNotEnabled();
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            
            if (GENESIS_TOKEN_CONTRACT.ownerOf(tokenId) != msg.sender) {
                revert YouMustOwnAllTheTokens();
            }
            
            if (hasClaimed[tokenId] == true) {
                revert AlreadyClaimed();
            }

            hasClaimed[tokenId] = true;

            emit Claim(tokenId, msg.sender);
        }

        _mint(msg.sender, NORMAL_DYNAMITE_TYPE_ID, _tokenIds.length, "");
    }

    function buyRadioactiveDynamite(uint8 _amount) public {
        if (!canExchange) {
            revert ExchangeNotEnabled();
        }

        uint256 price = _amount * RADIOACTIVE_DYNAMITE_PRICE;

        if (balanceOf(msg.sender, NORMAL_DYNAMITE_TYPE_ID) < price) {
            revert InsufficientFunds();
        }

        _burn(msg.sender, NORMAL_DYNAMITE_TYPE_ID, price);
        _mint(msg.sender, RADIOACTIVE_DYNAMITE_TYPE_ID, _amount, "");
    }

    function burn(address _owner, uint256 _id, uint256 _amount) external {
        if (address(0) == mutationContractAddress || msg.sender != mutationContractAddress) {
            revert OnlyTheMutationContractCanBurnTokensDirectly();
        }

        _burn(_owner, _id, _amount);
    }

    function walletClaimStatus(
        address _owner,
        uint256 _startId,
        uint256 _endId,
        uint256 _startBalance
    ) public view returns(ClaimStatus[] memory) {
        uint256 ownerBalance = GENESIS_TOKEN_CONTRACT.balanceOf(_owner) - _startBalance;
        ClaimStatus[] memory tokensData = new ClaimStatus[](ownerBalance);
        uint256 currentOwnedTokenIndex = 0;

        for (uint256 i = _startId; currentOwnedTokenIndex < ownerBalance && i <= _endId; i++) {
            if (GENESIS_TOKEN_CONTRACT.ownerOf(i) == _owner) {
                tokensData[currentOwnedTokenIndex] = ClaimStatus(i, hasClaimed[i]);

                currentOwnedTokenIndex++;
            }
        }

        assembly {
            mstore(tokensData, currentOwnedTokenIndex)
        }

        return tokensData;
    }

    function uri(uint256 _id) public view virtual override returns (string memory) {
        if (_id != NORMAL_DYNAMITE_TYPE_ID && _id != RADIOACTIVE_DYNAMITE_TYPE_ID) {
            revert InvalidTokenType();
        }

        string memory currentUriPrefix = super.uri(_id);

        return bytes(currentUriPrefix).length > 0
            ? string(abi.encodePacked(currentUriPrefix, Strings.toString(_id), URI_SUFFIX))
            : currentUriPrefix;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        _setURI(_uriPrefix);
    }

    function setCanClaim(bool _canClaim) public onlyOwner {
        canClaim = _canClaim;
    }

    function setCanExchange(bool _canExchange) public onlyOwner {
        canExchange = _canExchange;
    }

    function setMutationContractAddress(address _mutationContractAddress) public onlyOwner {
        mutationContractAddress = _mutationContractAddress;
    }
}