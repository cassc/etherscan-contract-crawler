// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/*
                                      ,,,,,ww,,,,,
                              ,a##M""`       ,#########mw,
                          ,##@#^            #################w
                      ,##",;#Qemmmmmmmmmmmw###################`%M,
                   ,##M""7#################   `""%W###########    7m
                 ,#"    ##################             `"%@###      `@p
               ,#"    ,##################                   j#%@m,     @Q
              #M     ,##################                    ]#    "@m,  `@
            ;#      ;##################                     @b       `%#mj#m
           ##      {##################                      #            7###
          #M"`````@#``^""""%WW#######Q                      #             @#@#
         @#      ,#                {#`""%W#Mm,,            ]#             j# ^#
        ]#       #                ,#           ^"%WMm,,    @b              #  ]b
        #b      @b                #                   `"%WM#,              #   @
       ]#      ,#                @M                       @b ""WMw,        #   ]b
       @b      #b               .#                        #       `"%Mw   ]#    #
       ##m     #                @b                       @#            `"@#Q    #
       #b "%m,@b               ]#                        #                ####m #
       @b     ##M,             #                        @b                #######
       @b     #   "%@m,       ]#                       ,#                @#######
       j#     #        "%@mw, @b                       #                 #######b
        @b   j#             `j##Mw,                   @#                @#######
         #    #              @#########Mm,,          ,#                ]#######
         "#,  #              ###################mm,,,#                ,#######b
          "##m#             .########################C""%WM#Mmmw,,,,,,########
           "# @#,           @########################                #^    @"
             @##`%#w        @#######################                #     #
              "#b   "@m,    #######################               ,#    @"
                %#      "WMw######################               {#   sM
                  "#,       #"W##################               #"  #M
                    `%m,    #     `"%W##########              a#,s#^
                       `%M, #              ``@#"%%WWWWWWWW%"@##M"
                           "%#m,            #"          ,a#M"
                                `"%M#mmw,,,#,,,,,sm##M"`

                                         HOVERCATS
                                   PLANET CROSSWORD 2022
                            https://hovercats.gg + hovercats.eth

*/

contract PlanetCrossword721 is ERC721AQueryable, AccessControl, ERC2981 {
  // Users with this role can mint. Allows us to shift that action to automated scripts or other processes,
  // without hooking up a bunch of powerful bots with full admin functionality.
  bytes32 public constant CONTENT_ROLE = keccak256("CONTENT_ROLE");

  string public baseURI; // Our variable base URI, settable with `setBaseURI`

  // The methods to transfer out ETH and ERC20s (`withdrawAll`, `withdrawTokens`) are public, but the recipient can only be sent once, in deployment.
  // This is that address.
  address public immutable paymentRecipient;

  address public royaltyRecipient;
  uint256 public royaltyAmount = 500; // 5% unless overridden

  // Opensea gasslist listings config
  address public openSeaProxyRegistryAddress;
  bool public openSeaProxyActive = true;

  error WithdrawalFailed();
  error AdminRoleRequired();
  error StaffRoleRequired();

  // @dev Used to restrict functions to addresses granted the Admin role.
  modifier onlyAdmin {
    if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)){
      revert AdminRoleRequired();
    }
    _;
  }

  /// @dev Used to restrict functions to addresses granted the Admin OR Content roles.
  ///      In other words, anyone with a role can perform functions guarded with this modifier.
  modifier onlyStaff {
    if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender) && !hasRole(CONTENT_ROLE, msg.sender)){
      revert StaffRoleRequired();
    }
    _;
  }

  constructor(
    string memory _argBaseURI,
    address _paymentRecipient,
    address _royaltyRecipient,
    address _openSeaProxyRegistryAddress
    ) ERC721A("Planet Crossword", "PXWD") {
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // Make sure the deployer is an admin.
      paymentRecipient = _paymentRecipient;
      baseURI = _argBaseURI;
      royaltyRecipient = _royaltyRecipient;
      openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
    }

  /// @notice This is how we mint.
  /// @dev Cannot be called directly by the public, only by staff.
  ///      In the future we may hook up an additional "store front" contract to handle more elaborate minting.
  function mint(address _recipient, uint256 _amount) public onlyStaff {
    _mint(_recipient, _amount);
  }

  /// @dev This lets us surface our custom baseURI variable.
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /// @notice Change the base token URI.
  function setBaseURI(string calldata newURI) external onlyAdmin {
    baseURI = newURI;
  }

  /// @notice ERC-2981 NFT royalty standard is supported.
  function royaltyInfo(uint256, uint256 salePrice)
  public
  view
  virtual
  override
  returns (address, uint256)
  {
    return (royaltyRecipient, (salePrice * royaltyAmount) / 10000);
  }

  /// @notice Update the royalty recipient and percentage.
  function setRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyAmount)
  external
  onlyAdmin
  {
    royaltyRecipient = _royaltyRecipient;
    royaltyAmount = _royaltyAmount;
  }

  /// @notice Transfers out the full ETH balance to the paymentRecipient.
  function withdrawAll() external {
    (bool success, ) = payable(paymentRecipient).call{
      value: address(this).balance
      }("");
      if (!success) {
        revert WithdrawalFailed();
      }
    }

  /// @notice Transfer out any ERC20s that got sent to this contract, most likely by accident.
  /// @dev Goes to the hard-coded payment address. Anyone can call this.
  /// @param _token The token/
  /// @param _amount The amount to transfer/
  function withdrawTokens(address _token, uint256 _amount)
  external
  {
    bool success = IERC20(_token).transfer(paymentRecipient, _amount);
    if (!success) {
      revert WithdrawalFailed();
    }    
  }

  /// @notice Allows toggling the OS gasless listing bit, in case it turns bad.
  /// @param _openSeaProxyActive The new status. False for disabled, obviously.
  function setOpenSeaProxyActive(bool _openSeaProxyActive)
  external
  onlyAdmin
  {
    openSeaProxyActive = _openSeaProxyActive;
  }

  /// @notice Change the ddress of the OpenSea proxy registry
  function setOpenSeaProxyRegistryAddress(address _proxyRegistryAddress)
  external
  onlyAdmin
  {
    openSeaProxyRegistryAddress = _proxyRegistryAddress;
  }

  function isApprovedForAll(address owner, address operator)
  public
  view
  override(ERC721A, IERC721A)
  returns (bool)
  {
    OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
      openSeaProxyRegistryAddress
      );
    if (
      openSeaProxyActive &&
      address(openSeaProxyRegistryAddress) != address(0) &&
      address(proxyRegistry.proxies(owner)) == operator
      ) {
      return true;
    }
    return super.isApprovedForAll(owner, operator);
  }

  /// @dev Let everyone know that we support ERC2981 (royalty payments)
  function supportsInterface(bytes4 _interfaceId)
  public
  view
  virtual
  override(AccessControl, ERC721A, IERC721A, ERC2981)
  returns (bool)
  {
    return
      super.supportsInterface(_interfaceId) ||
      ERC2981.supportsInterface(_interfaceId) ||
      ERC721A.supportsInterface(_interfaceId);
  }

  /// @notice Allow us to receive arbitrary ETH if sent directly.
  receive() external payable {}  
}

/// Needed to support OpenSea gasless listings
interface OpenSeaProxyRegistry {
  function proxies(address addr) external view returns (address);
}