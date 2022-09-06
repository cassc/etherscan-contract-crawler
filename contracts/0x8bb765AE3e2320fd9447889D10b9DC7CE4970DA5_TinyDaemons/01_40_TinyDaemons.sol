/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: TinyDaemons.sol
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice: TinyDaemons an LZ ERC 721
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./access/MaxAccess.sol";
import "./modules/TimeCop.sol";
import "./modules/NonblockingReceiver.sol";
import "./modules/ContractURI.sol";
import "./modules/PaymentSplitterV2.sol";
import "./modules/lzLlamas.sol";
import "./eip/2981/ERC2981Collection.sol";

contract TinyDaemons is MaxAccess
                      , TimeCop
                      , ContractURI
                      , PaymentSplitterV2
                      , ERC2981Collection
                      , lzLlamas
                      , ERC721
                      , ERC721Burnable
                      , NonblockingReceiver {

  using Strings for uint256;

  uint private gasForDestinationLzReceive = 350000;
  string base;

  event UpdatedBaseURI(string _old, string _new);
  event ThankYou(address user, uint amount);

  constructor() ERC721("TinyDaemons", "TINYDMN") {}

  modifier presaleChecks() {
    if (balanceOf(msg.sender) >= 4) {
      revert MaxSplaining({
        reason: string(
                  abi.encodePacked(
                    "Token: Ok ",
                    Strings.toHexString(uint160(msg.sender), 20),
                    " you have ",
                    Strings.toString(balanceOf(msg.sender)),
                    " maximum at this time is 4."
                  )
                )
      });
    }
    _;
  }

  modifier saleChecks() {
    if (balanceOf(msg.sender) >= 10) {
      revert MaxSplaining({
        reason: string(
                  abi.encodePacked(
                    "Token: Ok ",
                    Strings.toHexString(uint160(msg.sender), 20),
                    " you have ",
                    Strings.toString(balanceOf(msg.sender)),
                    " maximum at this time is 10."
                  )
                )
      });
    }
    _;
  }

  function presaleMint(
    uint quant
  ) external
    onlyPresale()
    presaleChecks() {
    if (quant > 2) {
      revert MaxSplaining({
        reason: string(
                  abi.encodePacked(
                    "Token: Ok ",
                    Strings.toHexString(uint160(msg.sender), 20),
                    " you wanted to mint ",
                    Strings.toString(quant),
                    " 2 or less please."
                  )
                )
      });
    }
    for (uint x = 0; x < quant;) {
      // this is a little sneaky to ensure you can't mint 1-2-2
      if (balanceOf(msg.sender) >= 4) {
        revert MaxSplaining({
        reason: string(
                  abi.encodePacked(
                    "Token: Ok ",
                    Strings.toHexString(uint160(msg.sender), 20),
                    " you wanted to mint ",
                    Strings.toString(quant),
                    " that puts you at ",
                    Strings.toString(quant + balanceOf(msg.sender)),
                    " maximum at this time is 4."
                  )
                )
        });
      }
      // mint it
      _safeMint(msg.sender, _nextUp());
      _oneRegularMint();
      unchecked { ++x; }
    }
  }

  function publicMint()
    external 
    onlySale()
    saleChecks() {
    _safeMint(msg.sender, _nextUp());
    _oneRegularMint();
  }

  function teamMint()
    external
    onlyDev() {
    uint quant = this.minterTeamMintsRemaining();
    for (uint x = 0; x < quant;) {
      // mint it
      _safeMint(this.owner(), _nextUp());
      _oneTeamMint();
      unchecked { ++x; }
    }
  }
    
  function donate()
    external
    payable {
    // thank you
    emit ThankYou(msg.sender, msg.value);
  }

  // @notice: Function to receive ether, msg.data must be empty
  receive() 
    external
    payable {
    // From PaymentSplitter.sol
    emit PaymentReceived(msg.sender, msg.value);
  }

  // @notice: Function to receive ether, msg.data is not empty
  fallback()
    external
    payable {
    // From PaymentSplitter.sol
    emit PaymentReceived(msg.sender, msg.value);
  }

  // @notice this is a public getter for ETH blance on contract
  function getBalance()
    external
    view
    returns (uint) {
    return address(this).balance;
  }

  // @notice: This sets the data for LZ minting
  // @param startNumber: What tokenID number to start with
  // @param authMint: How many to mint on this chain
  // @param teamMints: How many for team mint on this chain
  // @param string memory img: Provenance Hash of images in sequence
  // @param string memory json: Provenance Hash of metadata in sequence
  // @param newAddress: The address for the LZ Endpoint (see LZ docs)
  function setMinter (
    uint startNumber
  , uint authMint
  , uint teamMints
  , string memory img
  , string memory json
  , address newAddress
  ) external
    onlyDev {
    _setLZLlamasEngine( startNumber
                      , authMint
                      , teamMints);
    _setProvenance( img
                  , json);
    endpoint = ILayerZeroEndpoint(newAddress);
  }

  /*
   *     #@+                                             .                                     
   *    [email protected]@#                                             =#*+=---+**-                          
   *    %@@.                                               .==*@@@@+-                          
   *   [email protected]@*                                                  [email protected]@@*                             
   *  [email protected]@@                                                 .#@@#:                              
   *  *@@+        :                          ::   -:    +**@%@*=*-            .:   --    .:    
   *  @@%      =%@@@#@@. [email protected]@*   +*:  .*##+.  @@- *@@=   =%@@**++*+    .+##*.  @@= *@@= .%@@%   
   * [email protected]@=     #@@#[email protected]@@. #@@*  [email protected]@+ [email protected]@@%@+ [email protected]@:#--*#- -#%%.         [email protected]@@#@* [email protected]@:#-:*%*%@#-%= .
   * @@@    :#@@[email protected]@@: [email protected]@@ :*@@% [email protected]@@%%= [email protected]@#@-     .#@*          :@@@#%+ .%@#%=    %@##*@#*@
   * @@#  .*@@@%#%[email protected]@* [email protected]@@#*@#@@#%@@+: .-#*@@@*      *%%     ....  [email protected]*: .-#*@@@*    [email protected]% :%%-: 
   * [email protected]@[email protected]@=-%#-  [email protected]%@#:-*#[email protected]@@*:.%++%%=.%@@+       @@%#%**#@%@@@@*@*+%%+.%@@*     .%##@#    
   *   -==:         .-:     =%@@.    ::.   =%:        =%##+-.      .::::.   -#-        :-.     
   *                      [email protected]@@@=                                                               
   *                    .%@-*@#                                                                
   *                    %@[email protected]@.                                                                
   *                    [email protected]%@%:                                                                 
   *
   * @dev: This is the LayerZero functions for NonblockingReceiver.sol and more
   */

  // @notice: This function transfers the nft from your address on the 
  //          source chain to the same address on the destination chain
  // @param _chainId: the uint16 of desination chain (see LZ docs)
  // @param tokenId: tokenID to be sent
  function traverseChains(
    uint16 _chainId
  , uint tokenId
  ) public
    payable {
    if (msg.sender != ownerOf(tokenId)) {
      revert Unauthorized();
    }
    if (trustedRemoteLookup[_chainId].length == 0) {
      revert MaxSplaining({
        reason: "Token: Ok the Dev didn't set this paramater, contact MaxFlowO2.eth."
      });
    }

    // burn NFT, eliminating it from circulation on src chain
    _burn(tokenId);
    // fixes totalSupply()
    _subOne();

    // abi.encode() the payload with the values to send
    bytes memory payload = abi.encode(
                             msg.sender
                           , tokenId);

    // encode adapterParams to specify more gas for the destination
    uint16 version = 1;
    bytes memory adapterParams = abi.encodePacked(
                                   version
                                 , gasForDestinationLzReceive);

    // get the fees we need to pay to LayerZero + Relayer to cover message delivery
    // you will be refunded for extra gas paid
    (uint messageFee, ) = endpoint.estimateFees(
                            _chainId
                          , address(this)
                          , payload
                          , false
                          , adapterParams);

    // revert this transaction if the fees are not met
    if (messageFee > msg.value) {
      revert MaxSplaining({
        reason: string(
                  abi.encodePacked(
                    "Token: ",
                    Strings.toHexString(uint160(msg.sender), 20),
                    " sent ",
                    Strings.toString(msg.value),
                    " instead of ",
                    Strings.toString(messageFee)
                  )
                )
      });
    }

    // send the transaction to the endpoint
    endpoint.send{value: msg.value}(
      _chainId,                           // destination chainId
      trustedRemoteLookup[_chainId],      // destination address of nft contract
      payload,                            // abi.encoded()'ed bytes
      payable(msg.sender),                // refund address
      address(0x0),                       // 'zroPaymentAddress' unused for this
      adapterParams                       // txParameters 
    );
  }

  // @notice: just in case this fixed variable limits us from future integrations
  // @param newVal: new value for gas amount
  function setGasForDestinationLzReceive(
    uint newVal
  ) external onlyOwner {
    gasForDestinationLzReceive = newVal;
  }

  // @notice internal function to mint NFT from migration
  // @param _srcChainId - the source endpoint identifier
  // @param _srcAddress - the source sending contract address from the source chain
  // @param _nonce - the ordered message nonce
  // @param _payload - the signed payload is the UA bytes has encoded to be sent
  function _LzReceive(
    uint16 _srcChainId
  , bytes memory _srcAddress
  , uint64 _nonce
  , bytes memory _payload
  ) override
    internal {
    // decode
    (address toAddr, uint tokenId) = abi.decode(_payload, (address, uint));

    // mint the tokens back into existence on destination chain
    _safeMint(toAddr, tokenId);
    // fixes totalSupply()
    _addOne();
  }

  // @notice: will return gas value for LZ
  // @return: uint for gas value
  function currentLZGas()
    external
    view
    returns (uint256) {
    return gasForDestinationLzReceive;
  }  

  /*
   *       .=*#%@@@@%+                                     .:.                                 
   * .-+*%@@@@@@@-:::-*+                         =-=+**#%%@@@@%:     -*%@@@@%*-            #@@%
   * :*@%*=:[email protected]@@*                                +%@@%##*[email protected]@@@#    [email protected]@@@#=.   [email protected]:        [email protected]@@@@
   *       [email protected]@@#                                        [email protected]@@%-   -#@@@#:       @@:     [email protected]@@@@@=
   *      [email protected]@@#                                        *@@@*   .#@@@%:        [email protected]@-   [email protected]@@@@@@% 
   *     :@@@*                                   -*##%@@@@@#:  :*##+         :@@#      [email protected]%@@= 
   *    [email protected]@@@===-     .    ..                     *@@@@@+++.                [email protected]@%        #%%@#  
   * -#%@@@@@%##*=   @@@  [email protected]@@   -+*+-             [email protected]@@-                   [email protected]@*.       :@#@@.  
   *  +%@@@:        [email protected]@# #[email protected]@:-*@@@@@=           [email protected]@@:                  .=%*          =#@@#   
   *   %@@=      =+ #@@:#=: .++*@@*.%@: .:       :@@%.                  -*#-           %#@@-   
   *  [email protected]@@     -#%[email protected]@%%#.    :@@*    :---       @@@.                  :#+            .%@@@    
   *  [email protected]@+  .+%@%- *@@%%-     *@@   =%%++       :@@*                .-*+....:-*.      -#@@#:   
   *   #@*[email protected]@@=  :@@@@-      [email protected]%=#@@%-         .%@-               #%@@@@@@@@@@*.   [email protected]@@@@*  
   *    -*#*+:    [email protected]@+.        =###*:             =-               -**++++=-::::    :+**+=-.   
   *
   * @dev: These are the ERC721 functions/overrides plus ERC165 at the end
   */

  // @notice will update _baseURI() by onlyDeveloper() role
  // @param _base: Base for NFT's
  function setBaseURI(
    string memory _base
    )
    public
    onlyDev() {
    string memory old = base;
    base = _base;
    emit UpdatedBaseURI(old, base);
  }

  // @notice: This override sets _base as the string for tokenURI(tokenId)
  function _baseURI()
    internal
    view
    override
    returns (string memory) {
    return base;
  }

  // @notice: This override is for making string/number now string/number.json
  // @param tokenId: tokenId to pull URI for
  function tokenURI(
    uint256 tokenId
  ) public
    view
    virtual
    override (ERC721)
    returns (string memory) {
    if (!_exists(tokenId)) {
      revert MaxSplaining({
        reason: string(
                  abi.encodePacked(
                    "ERC721Metadata: URI query for ",
                    Strings.toString(tokenId),
                    " returns nonexistent token"
                  )
                )
      });
    }
    string memory baseURI = _baseURI();
    string memory json = ".json";
    return bytes(baseURI).length > 0 ? string(
                                         abi.encodePacked(
                                           baseURI
                                         , tokenId.toString()
                                         , json)
                                       ) : "";
  }

  // @notice: This override is to correct totalSupply()
  // @param tokenId: tokenId to burn
  function burn(
    uint256 tokenId
  ) public
    virtual
    override(ERC721Burnable) {
    //solhint-disable-next-line max-line-length
    if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
      revert MaxSplaining({
        reason: string(
                  abi.encodePacked(
                    "ERC721Burnable: ",
                    Strings.toHexString(uint160(msg.sender), 20),
                    " is not owner nor approved"
                  )
                )
      });
    }
    _burn(tokenId);
    // fixes totalSupply()
    _subOne();
  }

  // @notice: Standard override for ERC165
  // @param interfaceId: interfaceId to check for compliance
  // @return: bool if interfaceId is supported
  function supportsInterface(
    bytes4 interfaceId
  ) public
    view
    virtual
    override (
      ERC721
    , IERC165
    ) returns (bool) {
    return (
      interfaceId == type(IRole).interfaceId  ||
      interfaceId == type(IDeveloper).interfaceId  ||
      interfaceId == type(IDeveloperV2).interfaceId  ||
      interfaceId == type(IOwner).interfaceId  ||
      interfaceId == type(IOwnerV2).interfaceId  ||
      interfaceId == type(IERC2981).interfaceId  ||
      interfaceId == type(IMAX2981).interfaceId  ||
      interfaceId == type(IMAXPaymentSplitter).interfaceId  ||
      interfaceId == type(IPaymentSplitter).interfaceId  ||
      interfaceId == type(IMAX721).interfaceId  ||
      interfaceId == type(ILlamas).interfaceId  ||
      interfaceId == type(lzILlamas).interfaceId  ||
      interfaceId == type(ITimeCop).interfaceId  ||
      interfaceId == type(IContractURI).interfaceId  ||
      interfaceId == type(IMAXContractURI).interfaceId  ||
      interfaceId == type(ILayerZeroReceiver).interfaceId  ||
      super.supportsInterface(interfaceId)
    );
  }
}