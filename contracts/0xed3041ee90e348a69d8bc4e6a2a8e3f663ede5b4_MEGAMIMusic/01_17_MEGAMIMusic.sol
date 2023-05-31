// SPDX-License-Identifier: MIT

// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddxxxxddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxdol:;,''....'',;:lodxxxxxxxxxxxxxxxxxxxxxdlc;,''....'',;:codxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxdc;'.                .';ldxxxxxxxxxxxxxxdl;'.                ..;cdxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxdl;.                        .;ldxxxxxxxxxo;.                        .;ldxxxxxxxxxxxxxx
// xxxxxxxxxxxxxl,.                            .,lxxxxxxo;.                            .'ldxxxxxxxxxxxx
// xxxxxxxxxxxo;.                                .,lddo;.                                .;oxxxxxxxxxxx
// xxxxxxxxxxo'                                    ....                                    'lxxxxxxxxxx
// xxxxxxxxxl'                             .                   .                            .lxxxxxxxxx
// xxxxxxxxo,                             'c,.              .,c'                             'oxxxxxxxx
// xxxxxxxxc.                             .lxl,.          .,ldo.                             .:xxxxxxxx
// xxxxxxxd,                              .:xxxl,.      .,ldxxc.                              'oxxxxxxx
// xxxxxxxo'                               ,dxxxxl,.  .,ldxxxd;                               .lxxxxxxx
// xxxxxxxo.                               .oxxxxxxl::ldxxxxxo'                               .lxxxxxxx
// xxxxxxxd,                               .cxxxxxxxxxxxxxxxxl.                               'oxxxxxxx
// xxxxxxxx:.           ..                  ;xxxxxxxxxxxxxxxx:                  ..            ;dxxxxxxx
// xxxxxxxxo'           ''                  'oxxxxxxxxxxxxxxd,                  .'           .lxxxxxxxx
// xxxxxxxxxc.          ;,                  .lxxxxxxxxxxxxxxo.                  ';.         .cxxxxxxxxx
// xxxxxxxxxxc.        .c,                  .:xxxxxxxxxxxxxxc.                  'c.        .cdxxxxxxxxx
// xxxxxxxxxxxl'       'l,       ..          ,dxxxxxxxxxxxxd;          ..       'l,       'lxxxxxxxxxxx
// xxxxxxxxxxxxd:.     ;o,       .'          .oxxxxxxxxxxxxo'          ..       'o:.    .:dxxxxxxxxxxxx
// xxxxxxxxxxxxxxd:.  .cd,       .;.         .cxxxxxxxxxxxxl.         .,'       'ol.  .:oxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxo:.,od,       .:.          ;xxxxxxxxxxxx:          .:'       'oo,.:oxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxdodd,       .l,          'dxxxxxxxxxxd,          'l'       'oxodxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxd;       .l:.         .lxxxxxxxxxxo.          :o'       ,dxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxd:.     .ol.         .:xxxxxxxxxxc.         .co'     .:oxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxd:.   .oo'          ;dxxxxxxxxd;          .oo'   .:oxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxo:. .od;          'oxxxxxxxxo'          ,do' .:oxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxd::oxc.         .cxxxxxxxxl.         .:xd::oxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl.          ;xxxxxxxx:.         .lxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd;          'dxxxxxxd,          ,dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:.        .lxxxxxxo.        .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:.      .cxxxxxxc.      .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:.     ;dxxxxd;     .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:.   'oxxxxo'   .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:. .cxxxxl. .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:'cxxxxc,:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddxxxxddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
//
// MEGAMI https://www.megami.io/

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./rarible/royalties/contracts/LibPart.sol";
import "./rarible/royalties/contracts/LibRoyaltiesV2.sol";
import "./rarible/royalties/contracts/RoyaltiesV2.sol";

contract MEGAMIMusic is ERC1155URIStorage, Ownable, RoyaltiesV2 {

    /**
     * @dev The name of the token
     */
    string private _name = "MEGAMI-MUSIC";
    
    /**
     * @dev The symbol of the token
     */
    string private _symbol = "MEGAMI-MUSIC";

    /**
     * @dev The map managing the total supply for each token
     */
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev The struct holding the royalty info of a token
     */
    struct TokenRoyaltyInfo {
        address payable recipientAddress;
        uint96 percentageBasisPoint;
    }

    /**
     * @dev 100% in bases point
     */
    uint256 private constant HUNDRED_PERCENT_IN_BASIS_POINTS = 10000;

    /**
     * @dev Default royalty info used by all of the tokens
     */
    TokenRoyaltyInfo private defaultRoyaltyInfo;

    /**
     * @dev Map to manage a custom royalty info per token id.
     */
    mapping(uint256 => TokenRoyaltyInfo) private customRoyaltyInfo;

    /**
     * @dev Address of the fund manager contract
     */
    address private fundManager;

    /**
     * @dev Constractor of MEGAMI contract. Setting the fund manager and royalty recipient.
     * @param fundManagerContractAddress Address of the contract managing funds.
     */
    constructor(address fundManagerContractAddress) 
        ERC1155("") 
    {
        fundManager = fundManagerContractAddress;
        defaultRoyaltyInfo.recipientAddress = payable(fundManagerContractAddress);
        defaultRoyaltyInfo.percentageBasisPoint = 1000; // 10%
    }

    /**
     * @dev For receiving fund in case someone try to send it.
     */
    receive() external payable {}

    /**
     * @dev Set the address of the fund manager contract.
     * @param contractAddr Address of the contract managing funds.
     */
    function setFundManagerContract(address contractAddr)
        external
        onlyOwner
    {
        require(contractAddr != address(0), "invalid address");
        fundManager = contractAddr;
    } 

    /**
     * @dev Return the address of the fund manager contarct.
     */
    function getFundManagerContract() external view returns (address) {
        return fundManager;
    }    

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return totalSupply(id) > 0;
    }
    
    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }

    /**
     * @dev Set the base URI used by the all of the tokens
     */
    function setBaseURI(string memory newBaseURI) 
        external 
        onlyOwner 
    {
        _setBaseURI(newBaseURI);
    }

    /**
     * @dev Set the URI for a specific token 
     */
    function setTokenURI(uint256 tokenId, string memory newTokenURI) 
        public 
        onlyOwner 
    {
        _setURI(tokenId, newTokenURI);
    }

    /**
     * @dev create a new token
     * @param tokenId The tokenId of the token being created
     * @param _tokenURI The tokenURI of the token being created
     */
    function create(uint256 tokenId, string memory _tokenURI)
        external
        onlyOwner
    {
        require(!exists(tokenId), "token already exist");

        _mint(msg.sender, tokenId, 1, "");
        setTokenURI(tokenId, _tokenURI);
    }

    /**
     * @dev mint the specified token
     * @param to The address minted token is transferred to 
     * @param tokenId The tokenId of the token being minted
     * @param amount The amount of the token being minted
     */
    function mint(address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(to, tokenId, amount, data);
    }

    /**
     * @dev mint the specified tokens in batch
     * @param to The address minted tokens are transferred to
     * @param tokenIds The array of the tokenIds being minted
     * @param amounts The array of tokens' amounts being minted
     */
    function mintBatch(address to, uint256[] memory tokenIds, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, tokenIds, amounts, data);
    }

    /**
     * @dev mint a token and send it to recipients
     * @param tokenId the tokenId of the token being airdropped
     * @param amount the amount of the token being airdropped
     * @param recipients the list of addresses receiving the airdropped token
     */
    function airdrop(uint256 tokenId, uint256 amount, address[] memory recipients)
        external
        onlyOwner
    {
        uint256 recipientsLength = recipients.length;
        require(recipientsLength > 0, "no recipients");
        require(exists(tokenId), "token doesn't exist");
        require(amount > 0, "amount should be more than 0");

        for(uint256 i = 0; i < recipientsLength;) {
            mint(recipients[i], tokenId, amount, "");

            unchecked { ++i; }
        }
    }

    /**
     * @dev Burn the specified token
     * @param holder Holder's address of the token being burned
     * @param tokenId The tokenId of the token being burned
     * @param amount The mount of the token being burned
     */
	function burn(address holder, uint256 tokenId, uint256 amount) 
        public 
        onlyOwner 
    {
		_burn(holder, tokenId, amount);
	}

    /**
     * @dev Burn the specified tokens
     * @param holder Holder's address of the token being burned
     * @param tokenIds The tokenId of the tokens being burned
     * @param amounts The mount of the tokens being burned
     */
	function burnBatch(address holder, uint256[] memory tokenIds, uint256[] memory amounts) 
        public 
        onlyOwner 
    {
		_burnBatch(holder, tokenIds, amounts);
    }

    /**
     * @dev Set the royalty recipient and percentage for all of ids.
     * @param newDefaultRoyaltiesRecipientAddress The address of the new royalty receipient.
     * @param newDefaultPercentageBasisPoints The new percentagy basis points of the loyalty.
     */
    function setDefaultRoyaltyInfo(address payable newDefaultRoyaltiesRecipientAddress, uint96 newDefaultPercentageBasisPoints) 
        external 
        onlyOwner 
    {
        require(newDefaultRoyaltiesRecipientAddress != address(0), "invalid address");

        defaultRoyaltyInfo.recipientAddress = newDefaultRoyaltiesRecipientAddress;
        defaultRoyaltyInfo.percentageBasisPoint = newDefaultPercentageBasisPoints;
    }

    /**
     * @dev Set the royalty recipient and percentage for a specific id.
     * @param newCustomRoyaltiesRecipientAddress The address of the new royalty recipient. The custom setting can be reset by specifying zero address.
     * @param newCustomPercentageBasisPoints The new percentagy basis points of the loyalty.
     */
    function setCustomRoyaltyInfo(uint256 tokenId, address payable newCustomRoyaltiesRecipientAddress, uint96 newCustomPercentageBasisPoints) 
        external 
        onlyOwner 
    {
        customRoyaltyInfo[tokenId].recipientAddress = newCustomRoyaltiesRecipientAddress;
        customRoyaltyInfo[tokenId].percentageBasisPoint = newCustomPercentageBasisPoints;
    }

    /**
     * @dev Return royality information for Rarible.
     */
    function getRaribleV2Royalties(uint256 tokenId) 
        external 
        view 
        override 
        returns (LibPart.Part[] memory) 
    {
        address payable recipient = defaultRoyaltyInfo.recipientAddress;
        uint96 basisPoint = defaultRoyaltyInfo.percentageBasisPoint;

        if(customRoyaltyInfo[tokenId].recipientAddress != address(0)) {
            recipient = customRoyaltyInfo[tokenId].recipientAddress;
            basisPoint = customRoyaltyInfo[tokenId].percentageBasisPoint;
        }

        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = basisPoint;
        _royalties[0].account = recipient;
        return _royalties;
    }

    /**
     * @dev Return royality information in EIP-2981 standard.
     * @param _salePrice The sale price of the token that royality is being calculated.
     */
    function royaltyInfo(uint256 tokenId, uint256 _salePrice) 
        external 
        view 
        returns (address receiver, uint256 royaltyAmount) 
    {
        address payable recipient = defaultRoyaltyInfo.recipientAddress;
        uint96 basisPoint = defaultRoyaltyInfo.percentageBasisPoint;

        if(customRoyaltyInfo[tokenId].recipientAddress != address(0)) {
            recipient = customRoyaltyInfo[tokenId].recipientAddress;
            basisPoint = customRoyaltyInfo[tokenId].percentageBasisPoint;
        }

        return (recipient, (_salePrice * basisPoint) / HUNDRED_PERCENT_IN_BASIS_POINTS);
    }

    /**
     * @dev Allow owner to send funds directly to recipient. This is for emergency purpose and use moveFundToManager for regular withdraw.
     * @param recipient The address of the recipinet.
     */
    function emergencyWithdraw(address recipient) 
        external 
        onlyOwner 
    {
        require(recipient != address(0), "recipient shouldn't be 0");

        (bool sent, ) = recipient.call{value: address(this).balance}("");
        require(sent, "failed to withdraw");
    }

    /**
     * @dev Move all of funds to the fund manager contract.
     */
    function moveFundToManager()
        external 
        onlyOwner 
    {
        require(fundManager != address(0), "fundManager shouldn't be 0");

        (bool sent, ) = fundManager.call{value: address(this).balance}("");
        require(sent, "failed to move fund to FundManager contract");
    }

    /**
     * @dev ERC20s should not be sent to this contract, but if someone does, it's nice to be able to recover them.
     * @param token IERC20 the token address
     * @param amount uint256 the amount to send
     */
    function forwardERC20s(IERC20 token, uint256 amount) 
        public 
        onlyOwner 
    {
        token.transfer(msg.sender, amount);
    }    

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(ERC1155) 
        returns (bool) 
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if (interfaceId == type(IERC2981).interfaceId) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

  /**
   * @dev Return the name of the token
   */
  function name() public view returns (string memory) {
    return _name;
  }

  /**
   * @dev Return the symbol of the token
   */
  function symbol() public view returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Update the name and symbol of the token
   */
  function setNameAndSymbol(string calldata _newName, string calldata _newSymbol)
    external 
    onlyOwner 
  {
    _name = _newName;
    _symbol = _newSymbol;
  }
}