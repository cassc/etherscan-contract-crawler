//    SPDX-License-Identifier: MIT

/*    Art distributed under Creative Commons CC0 license
                                    
                                        HOWLERZ


                                          ..
                                       .;o:.
                                     .;dOo.
                                    'oOOOl.
          .o;                      ;xOOOOx,
          cNK:                    ,xOOOOOOx:.
         .xWWNk;.                .oOOOOOOOOko,.
         '0WWWWNOo;.             ,kOOOOOOOOOOOd,
         ;KOdOKXNWWXkoc;.        :OOOOOOOOOOOOOko.
         '0k:clloddddxxkkxc.     :kOOOOOOOOOOOOOOxl'
         .xNocooooolc:cccoxOd,   'xOOOOOOOOOOOOOOOOd.
          :NKlcooooo;'coolcl0Xd.  :kOOOOOOOOOOOOOOOO:
          .dWKlcooolccclooocc0W0'  ,xOkxxxkkOOOOkdodl;,,''.
           .kWXdclolcdd:looo:xWWo  .:xkkxxxkkxdodk000dlloxOOdc'
            .dXNOoclclOklccclOWWOclOKkl;,',lOX00NNXx'     ,OWWXd'  ..  .'.  '::. ...';,
              ,xXN0xl;c0NK00XWWWWWWWx.      .xWWNo..  .:'  ;KWWW0od0KolKNO:oNWWk;';:,,;''.
                'o0NXOookXWWWWWWWWWWk.   .:o;,0MO.    'ko. ,KWWWWWWWWX0NWWKXWNNNkc,;;;x0NXO;
                  .,lx0KKNWWWWWWWWWWNx.  .dXx'oWk.     .. 'kWWWWWWWWWWWWWWXOkOk0WOcccdNWWWWx.
                      .,OWWWWNOKWWWWWWO;  .,. cN0'     .;dKWWWWWWWWWWWWWWNkxNWNNWXxodkKXX0doc.
                 .   .'oXWWW0l,xWWWWWWWNk:.   :NK;..;lx0NWWWWWWWWWWWWWWWWWkd0KKOooo;;oc:o;'ox'
                .;lxk0XXO0W0:,,cOK0kxllodkOxlckWN0kkOO0KNWWWWWWNKxoc::dkxo,..:dl',d;'d:.oc ;o.
                   .,,'.,kWx,,;,;;,co,',,,:oxkkxo::;,,,;,;coxkd:.     'c.    :d,  ,..;. ;' .'
                      .l0WWk,,;;;;';:,'',;;,',oo,,;;;'.'.   ,dc       ..     '.
                .;lodOXWKkKXc';;;,..','',,,;',l:',,,,'.'.   ';.   ..''';;,.
                 .;cllc;.;KWKc'','';::,:o;',..'',::cl::o;..    .'';c::cclddc.
                      .,oOKNWKdc;;:lll:lo;,;;::clllllcldlcc;'';::',lccooc:ldo,
                 'codkKXO;:KOkNXOOOO0KXXK0OkxxxxxkO0KXNNXK0kdlodxxkOOd;;ol:oxd;
                  .;clc,..x0odOddXNOkXWWWWWWWWWWWWWWWWWWWWWWWWWWNk:'..  ,l:lddc.
                    ...,cx0kdOKkk0xxo0WWXOx0WWWWXkddkXWWWWWWWWWWk.     .:l:odd;
                    .;cl:';0WWNkoxKNxOW0xOd;xWWK:    cXWNk;;dXWWO,    .cdolddc.
                         ;0NXWW0lxWWKxxdKWd .dNk.     cXK,   'lxxl.   'oxddo:.
                       'okd,oNWWXNWWWKldNMx.  ,:.      'c'             .,,..
                       ... .dWWWWWWWWWNXWWK;
                           :XWWWWWWWWWWWWWW0:
                         'oXWWWWWWWWWWWWWWWWNOoc;,'....
               .',;:::ldOXWWWWWWWWWWWWWWWWWWWWWWWWNNXK0OOkxdl'
           .:dOKNWWWWWWWWWWWWWWWWWWNWWWWWWWWWWWWWWWWWWWWWWWWWXl
         'dKWWWWWWWWWWWWWWWWWWWWWWNOkKXNWWWWWWWWWWWWWWWWWWWWWW0,
        :XWWWWWWWWWWWWWWWWWWWWWWWWWNx:cxxd0WWWWWWWWWWWWWWWWWWWO.
       .xWWWWWWWWWWWNWWWWWWWWWWWWWWW0doloONWWWWWWWWW0KWWWWWWWX:
        :XWWWWWWWWWKkXWWWWWWWWWWWWWWKoc0WWWWWWWWWWMNxOWWWWWWNl
         :XWWWWWWWWKx0WWWWWWWWWWWWWWKxkXWWWWWWWWWWMXxOWWWWWWx.
          lNWWWWWWWNxOWWWWWWWWWWWWWWWWWWWWWWWWWWWWMKx0WWWWWX;
          ,KWWWWWWWWkxNWWWWWWWWWWWWWWWWWWWWWWWWWWWM0xKWWWWW0'
          ;KWWWWWWWWOxXWWWWWWWWWWWWWWWWWWWWWWWWWWWM0xKWWWWW0'
*/

pragma solidity ^0.8.0;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

interface ENS_Registrar {
    function setName(string calldata name) external returns (bytes32);
}

contract HOWLERZ is
    ERC721A,
    PaymentSplitter,
    Ownable,
    ReentrancyGuard,
    VRFConsumerBase
{
    using Strings for uint256;

    uint256 public constant MAXTOKENS = 5000;
    uint256 public constant TOKENPRICE = 0.13 ether;
    uint256 public constant WALLETLIMIT = 3;

    uint256 public startingBlock = 999999999;
    uint256 public tokenOffset;
    
    bool public revealed;
    string public baseURI;
    string public provenance;

    address public linkAddress = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address public VRF_coordinatorAddress = 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952;
    bytes32 internal keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    uint256 private fee = 2 ether;

    constructor(
        address[] memory payees,
        uint256[] memory shares,
        string memory unrevealedURI
    )
        public
        ERC721A("HOWLERZ", "HOWL", WALLETLIMIT)
        PaymentSplitter(payees, shares)
        VRFConsumerBase(VRF_coordinatorAddress, linkAddress)
    {
        baseURI = unrevealedURI;
    }


    //Returns token URI
    //Note that TokenIDs are shifted against the underlying metadata
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (!revealed) return _baseURI();
        uint256 shiftedTokenId = (tokenId + tokenOffset) % MAXTOKENS;
        return string(abi.encodePacked(_baseURI(), shiftedTokenId.toString()));
    }

    //Returns base URI
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    //Minting
    function AwooOOooooOoo(uint256 quantity) external payable nonReentrant {
        require(
            block.number >= startingBlock || 
            msg.sender==owner(), "Sale hasn't started yet!"  //allow owner to test mint immediately after deployment to confirm website functionality prior to activating the sale
        ); 
        require(
            totalSupply() + quantity <= MAXTOKENS,
            "Minting this many would exceed supply!"
        );
        require(
            _numberMinted(msg.sender) + quantity <= WALLETLIMIT,
            "There is a per-wallet limit!"
        );
        require(msg.value == TOKENPRICE * quantity, "Wrong ether sent!");
        require(msg.sender == tx.origin, "No contracts!");

        _safeMint(msg.sender, quantity);
    }

    function setStartingBlock(uint256 _startingBlock) external onlyOwner {
        startingBlock = _startingBlock;
    }

    //Provenance may only be set once, irreversibly
    function setProvenance(string memory _provenance) external onlyOwner {
        require(bytes(provenance).length == 0, "Provenance already set!");
        provenance = _provenance;
    }

    //Modifies the Chainlink configuration if needed
    function changeLinkConfig(
        uint256 _fee,
        bytes32 _keyhash
    ) external onlyOwner {
        fee = _fee;
        keyHash = _keyhash;
    }

    //To be called prior to reveal in order to set a token ID shift
    function requestOffset() public onlyOwner returns (bytes32 requestId) {
        LINK.transferFrom(owner(), address(this), fee);
        require(tokenOffset == 0, "Random offset already established");
        return requestRandomness(keyHash, fee);
    }

    //Chainlink callback
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        require(!revealed);
        tokenOffset = randomness % MAXTOKENS;
    }

    //Set Base URI
    function updateBaseURI(string memory newURI) external onlyOwner {
        baseURI = newURI;
    }

    //Reveals the tokens by updating to a new URI 
    //To be called after receiving a random token offset
    function reveal(string memory newURI) external onlyOwner {
        require(!revealed, "Already revealed");
        baseURI = newURI;
        revealed = true;
    }

    //To allow the contract to set a reverse ENS record
    function setReverseRecord(string calldata _name, address registrar_address)
        external
        onlyOwner
    {
        ENS_Registrar(registrar_address).setName(_name);
    }
}

/*
*   
*   Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
*   associated documentation files (the "Software"), to deal in the Software without restriction, including 
*   without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
*   copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the 
*   following conditions:

*   The above copyright notice and this permission notice shall be included in all copies or substantial portions 
*   of the Software.

*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
*   TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
*   THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
*   CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
*   DEALINGS IN THE SOFTWARE.
*   
*   Art and Concept by Noah Claire Davis
*   Twitter @HOWLERZNFT
*   
*   Smart contract developed for Howlerz by Jedi Development LLC
*/