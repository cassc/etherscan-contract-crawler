/**
                                               cNX:                                                  
                                             ;0Xkdd,                                                
                                            :kOOxdxx:                                               
                                          .cooc.ckddxc.                                             
                                         .llcl.  ;xxxOd.                                            
                                        .oc;l'     :KK0x'                                           
                                       .dc,o;    .,ldxxxk;                                          
                                      'd:.oc    .lOl..odokc                                         
                                     ,d:.ll.  ..dx:,...ldoOo.                                       
                                    ,d:.o0d::::l0Oolcc:cOOdOx.                                      
                                   ;0kc::,..    'lll:.  .,;lOk;.                                    
                                 ,loc.    ..';;:codxxc'.    .,coc.                                  
                              .;oc.  .';:::::,;ccc:c:;:::::'.  .;ol.                                
                             ;dc. .;cc:;.     .colc;.    .'::cc'  ;d:.                              
                           .lx'.,ll:.     .',:ddlllol:,.     .;ll:..oo.                             
                          .od',ol'    .;cccc:cko.,:xx:cccc:.    .co:'od.                            
                          ck:od'   .;ol:.     .dKOd:.    .:ol,    .ldcxo.                           
                         'OOxc   .:oc.    .';:ododxoc:,.    ,lo,    'dO0:                           
                      .. cN0;   .ol.    ,lcc;,dxcdkc';:cl:.   'ol.   .dNx...                        
                     ,Ox'oX:   'xc    'ol'    .,:'.     .co;   .ld.   .O0lk0,                       
                    :kdk0Ko   .dl    ;x;                  .dl.  .oo.   cXNxdO:                      
                  .ok:lkK0,   :kl;' ,x;       '::::,       ,k:   :0:   ,0Xx,;ko.                    
                 .dd;ox,ck;,::do:oxdxklc.   ,ol;,;:ld,   'co0x;clxXk:ccd0olk,'dx'                   
                'dkldd. ,Okl:l0kxklokockl  'x:      lx.  lxoko,dkd0k'..dXc ckc;xk;                  
               ;o,:0O;  .kx.  lkl:..o0o,.  .dl.    .dd.  .,x0; ,:;x:   cO, .dXx.,xc                 
              :o''o:':c' ck'  ;x'   'x:     .clclccl:.    .od.   :x.  .ko.;l;:ko..do.               
            .ll.;d;   'lc,do.  ld.   ;x;       .'..      .od.   'x:  .dOol;.  .xd..ox'              
           .o:.:d'      'cxKd. .ld.   'ol'      .      .:oc.   .dl  .oXO:.     .dx'.cx,             
          ,o,.co.         ,xXO;  ;d:.   ,ccc::llcodl;;cc:.    ,d:  .x0l.        .lk; ;x:            
        .co'.oo.            ;0Ko, .co:.   ..,o0: lNO;..     ,lo' .c00;            :Oc 'xl.          
       .oo.'xx,.......'''''',o0Okdc..:ll;.    :xkxd,    .':ol,.,lok0c..............l0l..do.         
      .okookOkkkxxxkOOOOkkkxxxxxdxOxlc;:cccclld0OOOdccccccc::ldKKk0KOOOOOOkkkxkkO000XXkox0d.        
          .................         .;lllccllldkcd0xllllclllc'..'''''''''.......''''''.....         
                                        .';cccokkkkdllc:,.                                          
                                         .,ccclokxllc;,,'.                                          
                                      .,c:;,....:,    .';cc,.                                       
                                    .;c;.  ''   ..    .. .'cl'                                      
                                   .cl.  .':x:       ;c'.   :d;                                     
                                  .:c.   .,;lkd::;;ckOl;,.   ;l'                                    
                                  ;o'        ;x, ..lk'       .l;                                    
                                  :l.        .ol .:xc        .:c.                                   
                                  :o.         ld.;kk;        .:o'                                   
                                  'o:        .ol 'ox;        .lc.                                   
                                   ,l'    .''oOl;clkd,'..   .;;.                                    
                                    'c,  .''lx;....'l:...  'l;                                      
                                     .cl,  ';.  .    .  .'cl;.                                      
                                       .;;::;,.:d:..'',::,..                                        
                                         ..':od:,cdo:...                                            
                                           .,cxl;ok:                                                
                                            ,:';;,,;.                                               
                                           ',. ',   ,,                                              
                                         .'.  .lo'   .;;:'                                          
                                      .,lc. .;l0Kdl;. .x0o.                                         
                                      .cd;.'cd0NXOOxl. 'l;                                          
                                     .,'cl;:oxxKKddlc:;c:',.                                        
                                    ',. ;o:,;cdKXko:'':o; .,.                                       
                                  .;'   .;cc:xKNN0xd:;c:.   ''                                      
                                 .oo;;;. ...c0XxxO0Kd,'...  .,;.                                    
                                ,okkkdllll:..od..o0d',oollocldl;.                                   
                              .:dkkxxoodllkl .:..,,..;lloddlcl:.',.                                 
                             ,;.:kxl;:o:ckk:.':;;;,. 'oddoodxd:. .,.                                
                           .::..,c;..'ccld:'.,;ll,,'..::;;'',,....,:.                               
                           .'..........'''...',:c'..             ...:,                              

 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./EIP712Allowlisting.sol";
import "./Phaseable.sol";
import "./FlexibleMetadata.sol";
import "./Nameable.sol";
import { Phase, PhaseNotActiveYet, PhaseExhausted, WalletMintsFilled } from "./SetPhaseable.sol";
import { SetInscribable, InscribableData, Script } from "./SetInscribable.sol";

interface ElderBond {    
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface ResidualBrainz {    
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external;
}     
contract RitualBindings is EIP712Allowlisting {  
    using SetInscribable for InscribableData;      
    InscribableData inscribable;

    address payable treasury;
    address currency;
    address legacy;

    uint64 constant ELDER = 0;
    uint64 constant INITIATE = 1;
    uint64 constant ACOLYTE = 2;
    uint64 constant OPEN = 3;
    uint256 constant NECRO = 0;
    uint256 constant MORTAL = 1; 
  

    constructor(string memory name, string memory symbol) FlexibleMetadata(name,symbol) {
        setSigningAddress(msg.sender);
        setDomainSeparator(name, symbol);
        Phase[] storage phases = getPhases();
                          
        phases.push(Phase(ELDER, 32, 381, 0));
        phases.push(Phase(INITIATE, 2, 441, 2500)); // BRAINZ
        phases.push(Phase(ACOLYTE, 3, 891, .02 ether)); // eth (480 after phases 1 & 2)
        phases.push(Phase(OPEN, 4, 1002, .04 ether)); // eth (111 after phases 1, 2, 3)
        
        initialize(phases,1002);
    }

    function isOsmRegisted(uint256 tokenId) external view returns (bool) {
      return enumerationExists(tokenId);
    }

    function summonCharun() internal view returns (address payable) {
      return treasury;
    }
    function invokeCharun(address charun) internal {
      treasury = payable(charun);
    }
    function seekBrainz() internal view returns (address) {
      return currency;
    }
    function consumeBrainz(address brainz) internal {
      currency = brainz;
    }
    function findElders() internal view returns (address) {
      return legacy;
    }
    function consumeElders(address elders) internal {
       legacy = elders;
    }

    function markGuardian(uint256 phase, uint256 quantity) internal {
      uint16[4] memory aux = getAux16(msg.sender);
      aux[phase] = uint16(quantity);
      setAux32(msg.sender,aux);
    }

    function canMint(uint256 phase, uint256 quantity) internal override virtual returns(bool) {
        uint256 activePhase = activePhase();
        if (phase > activePhase) {
            revert PhaseNotActiveYet();
        }
        uint256 requestedSupply = minted()+quantity;
        Phase memory requestedPhase = findPhase(phase);
        if (requestedSupply > requestedPhase.highestSupply) {
            revert PhaseExhausted();
        }
        uint16[4] memory aux = getAux16(msg.sender);
        uint256 requestedMints = quantity + aux[phase];

        if (requestedMints > requestedPhase.maxPerWallet) {
            revert WalletMintsFilled(requestedMints);
        }
        return true;
    }

    function script(uint256 scriptClass, uint256 tokenId, string memory btcAddress) internal {
      inscribable.script(scriptClass,tokenId,btcAddress);
    }    
    function retrieveRequests(uint256 scriptClass) external view returns (Script[] memory) {
      return inscribable.retrieveRequests(scriptClass);
    }    
    function inscript(string memory inscription, uint256 scriptClass, uint256 tokenId) internal {
      inscribable.inscribe(scriptClass,inscription,tokenId);
    }
    function findInscription(uint256 scriptClass, uint256 tokenId) public view returns (string memory) {
      return inscribable.findInscription(scriptClass,tokenId);
    }
    function inscriptionRequestExists(uint256 scriptClass, uint256 tokenId) public view returns (bool) {
      return inscribable.inscriptionRequestExists(scriptClass,tokenId);
    }
    function openInscription(uint256 scriptClass) public onlyOwner {
      inscribable.setInscribable(scriptClass,true);
    }
    function canInscribe(uint256 scriptClass, uint256 tokenId) public view returns (bool) {
      return (inscribable.inscribable(scriptClass) &&! inscribable.inscriptionRequestExists(scriptClass,tokenId));
    }
    function canTransform(uint256 scriptClass) internal view returns (bool) {
      return (inscribable.inscribable(scriptClass));
    }
}

/**
 * Ordo Signum Machina - 2023
 */