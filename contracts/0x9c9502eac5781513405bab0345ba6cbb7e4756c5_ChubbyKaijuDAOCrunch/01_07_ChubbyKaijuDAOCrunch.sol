pragma solidity ^0.8.10;

import "Ownable.sol";
import "ERC20.sol";

import "IChubbyKaijuDAOCrunch.sol";

/***************************************************************************************************
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-------------------------------------------://:-----------------------------------------------------
------------------------------:/osys+-----smddddo:--------------------------------------------------
-----------------------------ommhysymm+--oMy/:/sNm/-------------------------------------------------
----------------------------oMy/::::/hNy:Nm:::::/mN/------------------------------------------------
----------------------------dM/:::::::oNNMs:::::/+Nm++++/::-----------------------------------------
----------------------------dM/::::::::+NM+::+shdmmmddddmNmdy+:-------------------------------------
----------------------------yM+:::::::::hMoymNdyo+////////+symNho-----------------------------------
----------------------------+My:::::::::dMNho/////////////////+yNNs---------------------------------
-----------------------:+sso+Mm:::::::yNmy+//////////////////////sNNo-------------------------------
----------------------yNdyyhdMMo::::omNs+/////////////////////////+hMh------------------------------
---------------------/Md:::::+Nm::/hMh+/////////////////////////////sNd:----------------------------
---------------------+My::::::yMs/dNs+///////////////////////////////oNd----------------------------
---------------------:Md:::::::dNmNo/////////+++////////////////shmdhosMy---------------------------
----------------------dM+::::::/NMs////////+hmdmdo/////////////yNy-:dNodM/--------------------------
----------------------:Nm/:::::sMy////////+mN:`-Nm+///////////+Mh   :MhsMy--------------------------
-----------------------sMm+::::NN+////////sMs   sMs///////////oMs   -Md+Md--------------------------
----------------------sNdmNo::sMm+////////sMo   -Mh///////++oosMm-..sMs/Mm:-------------------------
----------------------mM:/ym+sNmy+////////+Md```+My///+oydmmmmmddmmmNMhshNm+------------------------
----------------------oMy:::hMh+///////////yMddmNN++sdmmdys+///////shhhNmhmM/-----------------------
-----------------------yMh:yMy////////////+mNyo+++smNhoodhh+///////shy/+smMMh-----/+osoo+:----------
------------------------oNmMN//////////////++////hMy+///+Mh////////dM+///+hMy---odMmdhhdmNNdo-------
-------------------------:hMd/////////////////sd+++/////+dy////////os/////+NN-/m++Mh+/oo+/oymNs-----
---------------------------Mm///////////++///+NMy/////////////////////////+NN-+m-hMsoo/ooo++ohMy----
---------------------------yMy//////////////smNdMms+/////////+ossyso+////odMosdddNhoooooooosyyNM:---
----------------------------hMy+///////+s+//yy++NMmNdhyssyhdNNNmmmmNNdhhmmh+yhyMmddhhhhhymNdddmNd+--
------------------------:::--sNms+//////+///++//sMd+oyhhhyssdMmhhhhdMmhMd/odMNMNmdmhhddhMNs+//+oyNh:
----------------------+dddddh+oMNs//////////++///sNd+:::::::/dMdhhdNNooMy/MNyyyhhhhdddmMNmmmmdo//sMh
---------------------oNh+//+hMNdo/////////////////omNy+::::::+MNhmMmo/hM+-hMmddhhds/:/NNo++oos+///dM
--------------------:Nm::::+mNs+///////////////////+sdmdyo+++oMMNmy++yMMs-/MmhhdddmmdhMNhhyso+////hM
----------------::::oMs:::sNd+////////////////////////oshdmmmmdyo++odNhyNd/mmddhyyyyhmMdyyhmms////dM
--------------/hmmmdmMo::hMh+////++osssso++///////////////++++++oydNdo//omN+/+oyhdmNNNMy////+////+NN
-------------/Nm+::/sMh:hMy///+sdmNmdddmNmds+////////////oddddmNmhyo/////+dNo-----/MmodNhs+//////sMs
-------------dM/:::::ssdMs//+yNNho+o++oooshNNy+//////////+ssso++//////////+dM+---+mNo//shmm+////oNm-
-------------Mm:::::::hMy//+dMh/+ooo/oo/+ooohMd+////////+++////////////////+mN/yNNy+//////////+yNm:-
-------------NN::::::sMh///dMyo+oooooooooooooyMd//+shmmmdddmmdho////////////oMMms//////////+dNNh+---
-------------hM+::::+Mm+//+MmooooooooooooosyhhmMmhNhs/::---::/sdNh+////+yo//+MN+////////////dM+-----
-------------/Mh::::dMo///+MNyyyyyyhhhhhddhdmddmMd::-----------:/hNy+//+Mm//yMs////////////oMd------
--------------hM+::oMh////+MNhdhhdddmddmmmNNddddMN:---------------+mmo//dMo/+o+////////////dM+------
------------:ohMm::mM+//+hNMNmmNNmdddhhyhdhhhddhNM/----------------:dNo/sMy///////////////oMd-------
-----------+NmsyMs+Md///hMymMmMNNmooo//hmddddddmMh------------------:mm++Mm///////////////dM/-------
-----------dM/::hhyMs///dMoyMNs+hMNddmNNdddhssshMy-------------------+My/mM+/////////////sMh--------
-----------dM/::::mM+///sMhyMh/oNmo//oMNmmmmmmmmy:--------------------mN/hMs////////////+NN:--------
-----------sMs::::NN////+dMNM+/mMo///+NNy+/oNN/:----------------------sMoyMy///////////+dN+---------
------------mN/::/Mm/////+yMN+oMd///+mNo///+NN------------------------+MsoMh//////////omN+----------
------------/Nd/:/Md/////+hMNddMm+/+dMs///+hMs------------------------/My+Md////////+yNm/-----------
-------------+Md//Mm////+mNsosyyNNhmMMs++odMs-------------------------:Mh+MNhso++oydNdo-------------
--------------+Nm/NN///+mMo/////+ossodNNNmy/--------------------------:Mh/MNsdmmmdyo:---------------
***************************************************************************************************/

contract ChubbyKaijuDAOCrunch is IChubbyKaijuDAOCrunch, ERC20, Ownable {

    mapping(address => bool) public controllers;

  
    constructor() ERC20("ChubbyKaijuDAOCrunch", "CRUNCH") {}

    function mint(address to, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can mint");
        _mint(to, amount);
    }


    function burn(address from, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can burn");
        _burn(from, amount);
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }
}