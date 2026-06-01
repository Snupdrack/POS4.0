import { NextResponse } from 'next/server'
import { db } from '@/lib/db'

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url)
    const productId = searchParams.get('productId')

    const where = productId ? { productId, active: true } : { active: true }

    const extras = await db.extra.findMany({
      where,
      orderBy: { sortOrder: 'asc' }
    })
    return NextResponse.json(extras)
  } catch (error) {
    console.error('Error fetching extras:', error)
    return NextResponse.json({ error: 'Error fetching extras' }, { status: 500 })
  }
}
