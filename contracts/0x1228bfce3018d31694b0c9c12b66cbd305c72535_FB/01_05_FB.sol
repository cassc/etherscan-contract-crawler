// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Federico Bebber
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    SrriYir:rr7i7L7iY77i7rLivrUr1L5UIIILqYPqrr1Ys15LKIbSRJ2EgPQREIgdDKBPPEDvsSQZgJb2ZvsUq122bEZ55ISvvvLi    //
//    ii:r7vrjvviriuvUL1svi777ivvjIKILrUIqIbYrrvr77X5KKS5ZdRdBEuqRZbZQZDggEBRQIvRQbMgEZgdMqRZDMBbqKPIdPZKi    //
//    s:rrI2uSdSP7IUEX11S77j1vs7UgKr7i7::7v77:vUjY2555P2ZXEPDZDPgPZSbDBbMDQQBQBDQRQDQQBQQDbMBMMPDEDqZZBQBL    //
//    r7rg121ZDgEgKq5PUK2P7jjv77r:.:::.: ..i:irqXEPgdDKgbKqESb5SisEgKMEgRQgRZQgQdRgBZQQBgQDQgQdEKddMPQgQRP    //
//    r:ruquPdgqdSd5X1qU2vsr7rrrv  .ii:.:.:rsirvgPdKgPUKXKZ25IZg2dBMRdgEZbBMQDQDBMRDgEQgQEgqgEBQQgBMRRQMBK    //
//    r7r5qg5DIP5P2qUbqSsj7UKXvqM:i5rr..i7:::BQRPgDRbEsXrX1P5P2gPK5dPEDQPdMBDQZBgQPgZggZZRbdqZdgDRgQgQDBQP    //
//    7iLsKuIXZbqSDUZ27LK1UrIj21ISr:r::::iririBBMMQgMSPKZ25uqu5Y2LIjLsdDMgQP1SEPgdREZPZMQPKdQdgdDIS2K2EDQr    //
//    irrD5K5XKPKKXbXPSSIDuUJIJKjPPdv5iIvsr7i7YEbQQBqXqbU2rUjuv17Ujvv7rbKEddSZqKqKIdgdPgPZuKgQZbSKJu1PqQRY    //
//    rivKbSgPdXZIbIDXP2XSL151I11u5qgDQQR1dX7iIMDJvirvs7vi77vrrr7rr7I777SJXKDqdERdgEMZQPgdDJZRbPQPI5P2U7Pi    //
//    rvEDPRZQZZ1gdEbEPP5X2PIbIqqPqEqQgZE77PP7rriiirrs7v:ii7r7r7rr:772rrrYrS12jRZMgPEMuKXQdbIguUKKKBIdPISv    //
//    7YQggEgPM5PPMPDgQKBXPPdbQgMZgZXUPIg7IQ5ir:i:i:iiv:i:i:rirrrrrir:vrvrrrU7KZEqgXDEPsgZPvYUUrIbRPZEDZQ5    //
//    J5IZbgDEPRdKjZd1XB  .7r7::iXdqKgXUqZIr:rrrr:.:.:.:::.:.i:i:i:ririvvvrri75jLUqgQgvs5UXs:ILruggEXDddPZ    //
//    jLgSK5ISDdD2g2 :u: .J7i. .::rrQEPQBiii77r:r.:.. . ......:...::i:::UXgv:iJv1KBKE5PIquZjr2riYKQXDdqvQ2    //
//    iY5Zgg1XSXvPBi r7rruiiii ..::rrdQZiiirivii..             . ..i.::i:YrE57:7LrrPIdXDqSrSS5rri5DPKDEBQu    //
//    LsDSddQDbYuPD.:.. ..i:ri. ..iiXE5:iivri.:::.               .::iiri::ri5ZL:rvrr7vS5EPbXDjriv1EqMMBEd:    //
//    ir112PXS1ZPB:ivv   . :ri:7vSgEiri7r7i::  .                 ::7rr:ri::vLIUr:rKXjs77vMEgdKvULXZPZgDJ:r    //
//    7rDSPUSudZB..JK. :r .1Di7D5vU:rXqvrir:i:rir::.    .       ..i7QBQL7:r:ri7gM:rsEqDS:sZPBUiiXPDbDdMIJi    //
//    i75522uDqBr rr   ::7BMui:71I77PSIEdgQBBBQBQBQqir.  .     ..7rbMQgQgq1RSrisQP:iDQEQPPZPqvi7XPDQdMgSq7    //
//    7rs1XYSjQD  : ..  7Ss7SJri7JI7r2DEMqI77ruEBQBQQXv.. .   ...rs1q5PZP7qQgXI7ZQBvXdgZBZBMMi:jgJDIPdQ7Lr    //
//    ivPZXSL7g  .. .r:::r:igQjriJssudSDIP1qEEsILqQQDQP7....     :7Li7r7i77PdB:iirQBIDXq5BMggBriSREPXggS5r    //
//    iigPPUPgi :ii iiuv:.r7Lu1YJrUSZDQdRDQRBgQU:.PgRgQMr..:i  .:.7i7r7rrrbPDQ: iiBZE2ZqMKgqbMBI7ERE5KZ1D:    //
//    :r2Ku2Lqr.rv. KJi77:.irvr7UgZEXQgRgMdQgRgX :QgZEBB7. .sv . :.::ri7i7iXYZKridgddPgQDPPQPgKMvi5ZPZI2gi    //
//    vivUIYJ7Iri::.rvj:rr:.::r:PdDDRdBgQgMgMMQBBQBQBX7r:   :Q1  :27::vYjrvYrv277UgKgPPDRRqPPXKLb:7KbSgRB.    //
//    i7r2vj7Lv2IXi::j77:77rii.gUq2DKDQQQBQBMBQBQBQP:..:..   rUI. :s7Y7vrJ77iJr.iPSDPZUdPRS5XK775g:UI51EMi    //
//    2r7vY7v7s71LQr.i77LiY7rrvQUEQZbXD1XsgBBBZii.:   :::.    :7K   i...r::.Lvi rsSXEPd2MqgsqvrrqqSLESPPZ:    //
//    rv727L7YJuJqSBr.:Lvv7LiirujDZB2Iii:riri:.: .   :rL..      ::     :::.r..  vjs2uSIq2PP5vSi77q1XqZ5Dv:    //
//    7i7r17Jij1XIqSBr.:Y7rrYrirQRgqJ7r:ri:.:.. ... .rLrri: ...                :srU1u2UJPIK77v77jY2UMbEqI:    //
//    i7Y1vu2Yi2UbSP2g7::Y7vYKir2ZKDKdX7rri7rL:. . ..7iQBBBBQBQY .         .ii:L7YjusZ5dqEIIjrrvvriYJSjPPr    //
//    7iI22jKP1iIIqE5LgS:.YsYISLdqQDBMg57:7rj::..   :rMEDdRdgPDQPi:   .  vIi7ir.:75LUbgbEXP5b7Yv2Y1Y5UbqP:    //
//    rv7UI7iL7vs22Ej7UPqr.r:7152BggRBDMjrii.:......iBZDXZKPqgEBdB.. ..:.rvr:r:i::ud72PXUDXX2S5PvuuISqPQPi    //
//    7rurr:riii7vqUI7YuEgKr:.7r5EdbQMBMR7i.:.....: 7BQZggQggQBQBr  ..:.::virr7rv.:QJrSLIXqIdKPIq1XY55ZgD:    //
//    rv7si777iv7I2b5I7LdgqB:i:i:iLMZMdMMQUr:i.:   .:2SPqgQBP: .     ..r:rs2XP7srL:21XJX2PIdIbIqISYj2PPDX:    //
//    vivJvrvri7Y1KdU77iIujIJivsPvErvDEdQRQZ7ii..     . .             .iLLSIEiir7::vMSqIK1S552q5J75XXIZDR:    //
//    rrrv7LrL:irL27rKLJvIIKiSIjKBJ.rQPgdRDZu7::.. .  .7vjri7gDP:..: ..rLDSqr:.iiriUUbSqUXIdSPIqvu1DKEPR5i    //
//    Lr7r7iJvvri:.:S7JJSII:1EiiPD..BgdEgdgbQPvir:::r1BQRgBBBgBQ. riJ77rr2DM7isr7iLPDSXJ51PqdjPJ2IPEgZgqv:    //
//    r77vri:i:Pi. r:iiv1PPDZQv::i PQBPMDDPDgRbEuX5DQBQBQBQBQBQBr7vvrr77:PSR.77ri75Z5X5P2PS57LIXvJ12jrLqri    //
//    vi7LriKi:iLiriIIPZBQQgQQBQBU:.i:rvS2REDPgZgQBBBgDKqvY17:iiirvQRgPiiUZ:.77iMdqUUUXIPqqr77P2LiL7UvSqu:    //
//    r7:riEqQi.:MIIXddMbgQBQBQgUBBBqJY5qDdgKgEgZQERPKvr.  ....i:::iiKgEvXv:igYJ1SJJ7U1SsvjrrsrjLvYUuXIdPi    //
//    urvvPLSIB.iQBD2EgPDQDr: . :ru1PPBQQPEPQdDEMY..PPQQBQBBBQBQBQBYYuSKQQviQX7YJrSj5j1U5isrvrs77vKsKIbYP:    //
//    57r17sKDPBgQPXEQEQQB.i.i:irdJYIqr:DgPgQPLRBKsXgBQBQBQQQBQBBBK5ru2dQ1:rEI7IIIUjvuLYL1rLrv7u72SPriiv7r    //
//    rijL7rEKPPD2IPBERMBK..irQYr77::...BMQgI.MgKXKZBBBMBQBQBQBMPvjvXSK5v:i7PvjUq1srJr7rs77i77sv7sgiirsvv:    //
//    iJ5PsjuSjuL1dDdDPQQI iiirBBIIBr::QBBQBjr7:.ririQQBPIi:.....rrv72Jsrris7vYX1vi777r7rvi7iL7J1Zi.:rr77i    //
//    v15UKs1JjYX5dSPqdgBb:vBi:.725ri:RBBQQYs7:.:::.:ii....     .:ii77rrSYjU5sKIuiLsX7Y7v7vrsLj7r..:7rs7Y:    //
//    rqXd5P5d2KXEPP5XXMQBr.vBEi::.:.:::::i72rivi.  .i::.:::::::.iirrsjEdq2qKJiJ72Jj1Jrvr2ii:i::.:iLrv7v7r    //
//    I2ZKb5S1U1bbZKgbDEBEBr..gBBR7:::r::.77ri7J7i7r7iiLJr5XP1Usu1P2EZQbbXSJ2sSLq1Sr2v77Xr. ::rrY7s7YrvrYi    //
//    jKqPuSj21q5EPZSZqPJ5KBPi..:i:iidPBU: . rQ7:jBB77vSMQRBMQQQdMqgdZqqUbIqSggS7YuPvL7L2Y.:.rrvrLrs7vi7ii    //
//    SIqSS5P1KIEKgEdIq2dPMZRBBri:r:uPjvKQi.:.i:rZQRLiPYMRQEMEgqPdgdZq5jX1PXg7..::77u7L7vrU7::i.::v7r.r7vi    //
//    2b5qJISqIPKZPDbZZQddZBZQQBBBQv:SdRMBr:r:.7QMZQPiv5UQXMbgKKKEPbKdXP55XDKr   ..77viv7s27r7:i:i::.rr7rr    //
//    qqZqXuqKEXZKgdMKgPEKgZMdREBDdgb1qSER::Lri:gQgdQivXb2DZQggqDPgSqXP5ZKbqP:..:.:.rrs7Iri:r:771rr:7rjvsi    //
//    XqPZ2qIEPgPEqDPdPgbgEMgZb5JXZDZBQBBr.iiXDi:BbMPU1Kq5KMgMPdbDq52PL5UX1ZK: ii7i7:ir17:.iivrs7i:L7Yvvri    //
//    UuXI271vuUSUSuIsPIPqdI5YKXPIgdBQBQi SQQgQ:rXBqK5D7Z5XPdKdKEPZqgbRdEPbEY .iri77r:i:..rrrr7ii:77vr7r7:    //
//    iJYUuv7L7Jv5JJvJY5vLYuuPXZKQdBQBi. IQMMBIuuRQXrQdSIqu22ZbgqZZgPsPdUbSRi.:vr7iv77i..rivrvrr:77vivrL7r    //
//    JLJs1vsvuvI25YUvsv77u1XJI2EgB7i. .QggDRQBP5PBZ:Z7LK:i:7MBggqDKdsSjUqDE. Lr7rv777i i::i7r7irivirrLrvi    //
//    vsYI5X71sjIP2P1SLIs5UduY1XqQ:::..SEPPgXQZJJ5MBiZ7dDSiJvBDBEdXbqPXb5QQi i7vrrruri..rr:7r7iririrrv7vrr    //
//    IvjUP5JJujK2PY7Ib5X1ZXY7sXP5i:i :BQDgQRgR15dQQuirXMsrLiQZEDdZuqSDXM7: :7vr7:rr..::7i7iri7:rrvirrLr77    //
//    2SIPSK5jvXsqISiuIEUISYiI5P1Kiri.:BZgdZDMPP1M:Zjr7gXYjRiddgPZdE5PPPr: :rY77ir:. i:r:rii:rivr7:i:rr77v    //
//    SuKKqU57uv1jI1bXqUPXPYI1KXKPdrr.LQQEgdgqqv7iub1ijbX7Mgr:RSbPqvSXY:..rivr7irii:iii:iii:ririi:ri7rvrvi    //
//    vvvJ77i7r7i7irr77v7JL7vJYsvXvr::UQKEjIKP::.:iSrrij:rPu::7uvsYvir...rr7ii:iii::.:::.::iir::.i:iir:i::    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FB is ERC721Creator {
    constructor() ERC721Creator("Federico Bebber", "FB") {}
}