# included by svgen.nim

template defDevice(d, m, p: string) =
  result[d] = DeviceSpec(module: m, ports: p.split())

proc mkDevices(): Table[string, DeviceSpec] =
  result = initTable[string, DeviceSpec]()
  
  defDevice("7400", "ic7400", "p1_a p1_b p1_y p2_a p2_b p2_y gnd p3_y p3_a p3_b p4_y p4_a p4_b vcc")
  defDevice("7402", "ic7402", "p1_y p1_a p1_b p2_y p2_a p2_b gnd p3_a p3_b p3_y p4_a p4_b p4_y vcc")
  defDevice("7404", "ic7404", "p1_a p1_y p2_a p2_y p3_a p3_y gnd p4_y p4_a p5_y p5_a p6_y p6_a vcc")
  defDevice("7408", "ic7408", "p1_a p1_b p1_y p2_a p2_b p2_y gnd p3_y p3_a p3_b p4_y p4_a p4_b vcc")
  defDevice("7432", "ic7432", "p1_a p1_b p1_y p2_a p2_b p2_y gnd p3_y p3_a p3_b p4_y p4_a p4_b vcc")
  defDevice("7486", "ic7486", "p1_a p1_b p1_y p2_a p2_b p2_y gnd p3_y p3_a p3_b p4_y p4_a p4_b vcc")
  defDevice("74138", "ic74138", "a0 a1 a2 e1_n e2_n e3 y7_n gnd y6_n y5_n y4_n y3_n y2_n y1_n y0_n vcc")
  defDevice("74151", "ic74151", "i3 i2 i1 i0 y y_n e_n gnd s2 s1 s0 i7 i6 i5 i4 vcc")
  defDevice("74153", "ic74153", "p1_e_n s1 p1_i3 p1_i2 p1_i1 p1_i0 p1_y gnd p2_y p2_y0 p2_i1 p2_i2 p2_i3 s0 p2_e_n vcc")
  defDevice("74157", "ic74157", "s p1_i0 p1_i1 p1_y p2_i0 p2_i1 p2_y gnd p3_y p3_i1 p3_i0 p4_y p4_y1 p4_i0 e_n vcc")
  defDevice("74244", "ic74244", "p1_oe_n p1_a0 p2_y0 p1_a1 p2_y1 p1_a2 p2_y2 p1_a3 p2_y3 gnd p2_a3 p1_y3 p2_a2 p1_y2 p2_a1 p1_y1 p2_a0 p1_y0 p2_oe_n vcc")
  defDevice("74273", "ic74273", "mr_n q0 d0 d1 q1 q2 d2 d3 q3 gnd cp q4 d4 d5 q5 q6 d6 d7 q7 vcc")
  defDevice("74283", "ic74283", "s2 b2 a2 s1 a1 b1 cin gnd cout s4 b4 a4 s3 a3 b3 vcc")
  defDevice("28256", "ic28256", "a14 a12 a7 a6 a5 a4 a3 a2 a1 a0 io0 io1 io2 gnd io3 io4 io5 io6 io7 ce_n a10 oe_n a11 a9 a8 a13 we_n vcc")
  defDevice("62256", "ic62256", "a14 a12 a7 a6 a5 a4 a3 a2 a1 a0 io0 io1 io2 gnd io3 io4 io5 io6 io7 ce_n a10 oe_n a11 a9 a8 a13 we_n vcc")

const devices = mkDevices()
